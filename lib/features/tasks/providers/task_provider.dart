import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/models/task_status.dart';
import 'package:taskwin/services/firebase_service.dart';
import 'package:taskwin/core/constants.dart';
import 'package:taskwin/services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<TaskModel> _allTasks = [];
  List<TaskModel> _liveTasks = [];
  List<TaskModel> _waitingTasks = [];
  List<TaskModel> _completedTasks = [];
  bool _isLoading = false;
  double _totalBalance = 0.0;

  List<TaskModel> get allTasks => _allTasks;
  List<TaskModel> get liveTasks => _liveTasks;
  List<TaskModel> get waitingTasks => _waitingTasks;
  List<TaskModel> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  double get totalBalance => _totalBalance;

  void _updateCategorizedLists() {
    _waitingTasks =
        _allTasks.where((task) => task.status == TaskStatus.waiting).toList();
    _liveTasks =
        _allTasks.where((task) => task.status == TaskStatus.started).toList();
    _completedTasks =
        _allTasks.where((task) => task.status == TaskStatus.completed).toList();
  }

  /// Automatically complete any started tasks whose endTime has passed.
  Future<void> _completeExpiredTasks() async {
    final now = DateTime.now();
    for (var task in _liveTasks) {
      if (task.endTime != null && task.endTime!.isBefore(now)) {
        await distributePrizes(task.id);
      }
    }
  }

  Future<void> loadAllTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.tasksCollection
          .orderBy('createdAt', descending: true)
          .get();

      _allTasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      _updateCategorizedLists();
      await _completeExpiredTasks(); // check for expired tasks
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLiveTasks() async {
    try {
      final snapshot = await FirebaseService.tasksCollection
          .where('status', isEqualTo: TaskStatus.started.index)
          .orderBy('endTime')
          .get();

      _liveTasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      await _completeExpiredTasks(); // check for expired tasks
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading live tasks: $e');
    }
  }

  Future<bool> createTask(
    TaskModel task, {
    required bool isTemplate,
    required bool autoStart,
  }) async {
    try {
      final userId = FirebaseService.currentUser!.uid;
      // Total pool = stakeAmount * maxParticipants (no fee deducted yet)
      final totalPool = task.stakeAmount * task.maxParticipants;

      final taskData = task.toFirestore()
        ..addAll({
          'hostId': userId,
          'prizePool': totalPool, // store full stakes
          'createdAt': FieldValue.serverTimestamp(),
        });

      final docRef = await FirebaseService.tasksCollection.add(taskData);
      final taskId = docRef.id.length >= 8
          ? docRef.id.substring(0, 8).toUpperCase()
          : docRef.id.toUpperCase();
      await docRef.update({'taskId': taskId});

      if (isTemplate) {
        await FirebaseService.usersCollection
            .doc(userId)
            .collection('templates')
            .add(taskData);
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating task: $e');
      debugPrint(stackTrace.toString());
      throw e;
    }
  }

  Future<bool> joinTask(String taskId, String userId,
      {bool skipEntryCreation = false}) async {
    try {
      final taskRef = FirebaseService.tasksCollection.doc(taskId);
      TaskModel? updatedTask;
      bool shouldAutoStart = false;

      await FirebaseService.firestore.runTransaction((transaction) async {
        final taskDoc = await transaction.get(taskRef);
        final task = TaskModel.fromFirestore(taskDoc);

        if (task.status != TaskStatus.waiting) {
          throw Exception('Task is not joinable');
        }
        if (task.currentParticipants >= task.maxParticipants) {
          throw Exception('Task is full');
        }
        if (task.participantIds.contains(userId)) {
          throw Exception('Already joined');
        }

        // Deduct stake from user's wallet
        await FirebaseService.updateWalletBalance(
          userId: userId,
          amount: -task.stakeAmount,
          type: 'stake',
          description: 'Joined task: ${task.title}',
        );

        final newParticipants = [...task.participantIds, userId];
        transaction.update(taskRef, {
          'participantIds': newParticipants,
          'currentParticipants': newParticipants.length,
        });

        updatedTask = task.copyWith(
          participantIds: newParticipants,
          currentParticipants: newParticipants.length,
        );

        // Check auto-start condition using the updated count
        if (task.autoStart && newParticipants.length >= task.maxParticipants) {
          shouldAutoStart = true;
        }
      });

      // After transaction, create entry if needed
      if (!skipEntryCreation) {
        await FirebaseService.entriesCollection.add({
          'taskId': taskId,
          'userId': userId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // If auto-start condition met, start the task now
      if (shouldAutoStart) {
        await _startTask(taskId);
        // After starting, fetch the updated task (status = started, endTime set)
        final startedDoc =
            await FirebaseService.tasksCollection.doc(taskId).get();
        if (startedDoc.exists) {
          updatedTask = TaskModel.fromFirestore(startedDoc);
          _scheduleTaskNotifications(updatedTask!);
        }
      }

      // Update local list
      if (updatedTask != null) {
        final index = _allTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _allTasks[index] = updatedTask!;
        } else {
          _allTasks.add(updatedTask!);
        }
        _updateCategorizedLists();
        notifyListeners();
      } else {
        await loadAllTasks(); // fallback
      }

      return true;
    } catch (e) {
      debugPrint('Error joining task: $e');
      return false;
    }
  }

  Future<void> _startTask(String taskId) async {
    final taskRef = FirebaseService.tasksCollection.doc(taskId);
    await FirebaseService.firestore.runTransaction((transaction) async {
      final taskDoc = await transaction.get(taskRef);
      final task = TaskModel.fromFirestore(taskDoc);
      final startTime = DateTime.now();
      final endTime = startTime.add(Duration(hours: task.votingDurationHours));
      transaction.update(taskRef, {
        'status': TaskStatus.started.index,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      });
    });
  }

  void _scheduleTaskNotifications(TaskModel task) {
    if (task.endTime == null) return;
    final endTime = task.endTime!;
    final oneHourBefore = endTime.subtract(const Duration(hours: 1));

    if (oneHourBefore.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: task.id.hashCode,
        title: 'Voting ends soon',
        body: 'Voting for "${task.title}" ends in 1 hour.',
        scheduledTime: oneHourBefore,
      );
    }

    NotificationService().scheduleNotification(
      id: task.id.hashCode + 1,
      title: 'Voting ended',
      body: 'Voting for "${task.title}" has ended. Check results!',
      scheduledTime: endTime,
    );
  }

  Future<bool> startTask(String taskId) async {
    try {
      await _startTask(taskId);
      final taskDoc = await FirebaseService.tasksCollection.doc(taskId).get();
      if (taskDoc.exists) {
        final updatedTask = TaskModel.fromFirestore(taskDoc);
        final index = _allTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        } else {
          _allTasks.add(updatedTask);
        }
        _updateCategorizedLists();
        notifyListeners();
        _scheduleTaskNotifications(updatedTask);
      }
      return true;
    } catch (e) {
      debugPrint('Error starting task: $e');
      return false;
    }
  }

  Future<void> submitVote(String taskId, String entryId, String userId) async {
    try {
      final voteQuery = await FirebaseService.votesCollection
          .where('taskId', isEqualTo: taskId)
          .where('userId', isEqualTo: userId)
          .get();

      if (voteQuery.docs.isNotEmpty) {
        throw Exception('Already voted for this task');
      }

      await FirebaseService.votesCollection.add({
        'taskId': taskId,
        'entryId': entryId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final entryRef = FirebaseService.entriesCollection.doc(entryId);
      await entryRef.update({
        'voteCount': FieldValue.increment(1),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting vote: $e');
    }
  }

  Future<void> distributePrizes(String taskId) async {
    try {
      final taskRef = FirebaseService.tasksCollection.doc(taskId);
      final taskDoc = await taskRef.get();
      final task = TaskModel.fromFirestore(taskDoc);

      // Only distribute if task is started and not already completed
      if (task.status != TaskStatus.started) return;

      final totalPool = task.prizePool; // total stakes collected

      final entriesQuery = await FirebaseService.entriesCollection
          .where('taskId', isEqualTo: taskId)
          .orderBy('voteCount', descending: true)
          .get();

      if (entriesQuery.docs.isEmpty) {
        // No entries – just mark as completed
        await taskRef.update({'status': TaskStatus.completed.index});
        return;
      }

      final winnerEntry = entriesQuery.docs.first;
      final winnerId = winnerEntry['userId'];
      final winnerAmount = totalPool * AppConstants.winnerShare;
      final hostAmount = totalPool * AppConstants.hostShare;
      final platformAmount = totalPool * AppConstants.platformShare;

      // Credit winner
      await FirebaseService.updateWalletBalance(
        userId: winnerId,
        amount: winnerAmount,
        type: 'winning',
        description: 'Won task: ${task.title}',
      );

      // Credit host
      await FirebaseService.updateWalletBalance(
        userId: task.hostId,
        amount: hostAmount,
        type: 'host_bonus',
        description: 'Host bonus for task: ${task.title}',
      );

      // Credit platform (if platformUserId is set)
      if (AppConstants.platformUserId.isNotEmpty) {
        await FirebaseService.updateWalletBalance(
          userId: AppConstants.platformUserId,
          amount: platformAmount,
          type: 'platform_fee',
          description: 'Platform fee from task: ${task.title}',
        );
      }

      // 🔥 NEW: Record the win in the winner's user document (for victory pop‑up)
      await FirebaseService.usersCollection.doc(winnerId).set({
        'lastWin': {
          'taskId': taskId,
          'taskTitle': task.title,
          'prizeAmount': winnerAmount,
          'wonAt': FieldValue.serverTimestamp(),
          'viewed': false,
        }
      }, SetOptions(merge: true));

      // Update task document
      await taskRef.update({
        'status': TaskStatus.completed.index,
        'winnerInfo': {
          'userId': winnerId,
          'prizeAmount': winnerAmount,
          'winningEntryId': winnerEntry.id,
          'distributedAt': FieldValue.serverTimestamp(),
        },
        'hostBonus': hostAmount,
        'platformFee': platformAmount,
      });

      // Refresh local lists
      final updatedTask = TaskModel.fromFirestore(await taskRef.get());
      final index = _allTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _allTasks[index] = updatedTask;
      } else {
        _allTasks.add(updatedTask);
      }
      _updateCategorizedLists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error distributing prizes: $e');
    }
  }

  TaskModel? getTaskById(String id) {
    try {
      return _allTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }
}
