import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskwin/features/tasks/models/task_status.dart';

class TaskModel {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final String category;
  final double stakeAmount;
  final int minParticipants;
  final int maxParticipants;
  final int currentParticipants;
  final TaskStatus status;
  final String entryType;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final int votingDurationHours;
  final double prizePool;
  final List<String> participantIds;
  final Map<String, dynamic>? winnerInfo;
  final bool isPublic;
  final String? taskId;
  final bool autoStart;

  TaskModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.category,
    required this.stakeAmount,
    required this.minParticipants,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.entryType,
    required this.createdAt,
    this.startTime,
    this.endTime,
    required this.votingDurationHours,
    required this.prizePool,
    required this.participantIds,
    this.winnerInfo,
    this.isPublic = true,
    this.taskId,
    this.autoStart = false,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      stakeAmount: (data['stakeAmount'] as num?)?.toDouble() ?? 0.0,
      minParticipants: data['minParticipants'] ?? 2,
      maxParticipants: data['maxParticipants'] ?? 50,
      currentParticipants: data['currentParticipants'] ?? 0,
      status: TaskStatus.values[data['status'] ?? 0],
      entryType: data['entryType'] ?? 'Photo',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      votingDurationHours: data['votingDurationHours'] ?? 24,
      prizePool: (data['prizePool'] as num?)?.toDouble() ?? 0.0,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      winnerInfo: data['winnerInfo'],
      isPublic: data['isPublic'] ?? true,
      taskId: data['taskId'],
      autoStart: data['autoStart'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'title': title,
      'description': description,
      'category': category,
      'stakeAmount': stakeAmount,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'status': status.index,
      'entryType': entryType,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'votingDurationHours': votingDurationHours,
      'prizePool': prizePool,
      'participantIds': participantIds,
      'winnerInfo': winnerInfo,
      'isPublic': isPublic,
      'taskId': taskId,
      'autoStart': autoStart,
    };
  }

  /// Creates a copy of this TaskModel with the given fields replaced.
  TaskModel copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    String? category,
    double? stakeAmount,
    int? minParticipants,
    int? maxParticipants,
    int? currentParticipants,
    TaskStatus? status,
    String? entryType,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
    int? votingDurationHours,
    double? prizePool,
    List<String>? participantIds,
    Map<String, dynamic>? winnerInfo,
    bool? isPublic,
    String? taskId,
    bool? autoStart,
  }) {
    return TaskModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      stakeAmount: stakeAmount ?? this.stakeAmount,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      entryType: entryType ?? this.entryType,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      votingDurationHours: votingDurationHours ?? this.votingDurationHours,
      prizePool: prizePool ?? this.prizePool,
      participantIds: participantIds ?? this.participantIds,
      winnerInfo: winnerInfo ?? this.winnerInfo,
      isPublic: isPublic ?? this.isPublic,
      taskId: taskId ?? this.taskId,
      autoStart: autoStart ?? this.autoStart,
    );
  }
}
