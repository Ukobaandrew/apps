import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskwin/features/tasks/providers/task_provider.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/core/constants.dart';
import 'package:taskwin/services/firebase_service.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedFilter = 'Trending';
  String _userName = 'User';
  double _userBalance = 0.0;
  List<TaskModel> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.loadLiveTasks().then((_) {
        _applyFilter();
      });
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseService.usersCollection.doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = data['displayName'] ?? user.displayName ?? 'User';
            _userBalance = (data['balance'] ?? 0.0).toDouble();
          });
        } else {
          setState(() {
            _userName = user.displayName ?? 'User';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  void _applyFilter() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allLive = taskProvider.liveTasks;
    if (_selectedFilter == 'Trending') {
      allLive.sort(
          (a, b) => b.participantIds.length.compareTo(a.participantIds.length));
      _filteredTasks = List.from(allLive);
    } else if (_selectedFilter == 'Ending Soon') {
      allLive.sort((a, b) {
        if (a.endTime == null) return 1;
        if (b.endTime == null) return -1;
        return a.endTime!.compareTo(b.endTime!);
      });
      _filteredTasks = List.from(allLive);
    } else {
      _filteredTasks =
          allLive.where((task) => task.category == _selectedFilter).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER (fixed overflow by using Expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Hi, $_userName!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "₦${NumberFormat('#,###').format(_userBalance)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 FILTER TABS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...AppConstants.categories.map((category) {
                      final isSelected = _selectedFilter == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildTab(category, isSelected),
                      );
                    }),
                    _buildTab('Ending Soon', _selectedFilter == 'Ending Soon'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 TASK LIST
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TaskPreviewCard(
                                task: task,
                                onVote: () => _handleVote(task.id),
                                onShare: () => _shareTask(task),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleVote(String taskId) {
    final task = _filteredTasks.firstWhere((t) => t.id == taskId);
    Navigator.pushNamed(context, '/voting', arguments: task);
  }

  void _shareTask(TaskModel task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share task: ${task.title}')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No live tasks at the moment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or create a new task!',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-task'),
            icon: const Icon(Icons.add),
            label: const Text('Create Task'),
          ),
        ],
      ),
    );
  }
}

/// 🔥 TASK CARD UI (unchanged, but included for completeness)
class TaskPreviewCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onVote;
  final VoidCallback onShare;

  const TaskPreviewCard({
    super.key,
    required this.task,
    required this.onVote,
    required this.onShare,
  });

  String _getTimeLeft() {
    if (task.endTime == null) return 'No deadline';
    final duration = task.endTime!.difference(DateTime.now());
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min left';
    } else {
      return 'Ending soon';
    }
  }

  String _getImageUrl() {
    switch (task.category) {
      case 'Fun':
        return 'https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=400';
      case 'Creative':
        return 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400';
      case 'Dance':
        return 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400';
      case 'Beauty':
        return 'https://images.unsplash.com/photo-1522337660859-02fbefca4702?w=400';
      case 'Sports':
        return 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400';
      default:
        return 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_getImageUrl()),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${task.stakeAmount} entry • ${_getTimeLeft()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onVote,
                        child: Row(
                          children: [
                            const Icon(Icons.favorite,
                                color: Colors.pinkAccent, size: 18),
                            const SizedBox(width: 5),
                            Text(
                              '${task.participantIds.length} ${task.participantIds.length == 1 ? 'Participant' : 'Participants'}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onShare,
                        icon: const Icon(Icons.share, color: Colors.white70),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
