import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taskwin/features/tasks/models/task_status.dart';
import 'package:taskwin/features/tasks/providers/task_provider.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/widgets/countdown_timer.dart';
import 'package:taskwin/features/voting/screens/voting_screen.dart';
import 'package:taskwin/features/join/screens/join_task_screen.dart';
import 'package:taskwin/features/results/screens/results_screen.dart';
import 'package:taskwin/services/firebase_service.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  // Helper for category background image (matches Feed/Tasks)
  String _getCategoryImageUrl(String category) {
    switch (category) {
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.waiting:
        return Colors.orange;
      case TaskStatus.started:
        return Colors.green;
      case TaskStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.waiting:
        return 'WAITING';
      case TaskStatus.started:
        return 'LIVE';
      case TaskStatus.completed:
        return 'COMPLETED';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final task = taskProvider.getTaskById(taskId);

    if (task == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Task not found', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    final bool isHost = task.hostId == FirebaseService.currentUser?.uid;
    final bool isParticipant =
        task.participantIds.contains(FirebaseService.currentUser?.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          task.title,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.orange),
            onPressed: () => _shareTask(context, task),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with category image (like Feed card)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image:
                            NetworkImage(_getCategoryImageUrl(task.category)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(task.status)
                                      .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(task.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${task.currentParticipants}/${task.maxParticipants}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.attach_money,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '₦${task.stakeAmount}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const Spacer(),
                              if (task.endTime != null)
                                CountdownTimer(
                                  endTime: task.endTime!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prize pool card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Prize Pool',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₦${task.prizePool.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Task info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow('Description', task.description),
                    const Divider(height: 24),
                    _buildInfoRow('Category', task.category),
                    const Divider(height: 24),
                    _buildInfoRow(
                        'Entry Fee', '₦${task.stakeAmount.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildInfoRow('Entry Type', task.entryType),
                    if (task.startTime != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow('Started',
                          DateFormat('MMM dd, HH:mm').format(task.startTime!)),
                    ],
                    if (task.endTime != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow('Ends',
                          DateFormat('MMM dd, HH:mm').format(task.endTime!)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Task ID card (sharable)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        'Task ID: ${task.taskId ?? task.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.orange),
                      onPressed: () {
                        // TODO: Copy to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons based on status
            if (task.status == TaskStatus.waiting)
              _buildWaitingActions(
                  context, task, isParticipant, isHost, taskProvider),

            if (task.status == TaskStatus.started)
              _buildStartedActions(context, task, isParticipant),

            if (task.status == TaskStatus.completed)
              _buildCompletedActions(context, task),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingActions(
    BuildContext context,
    TaskModel task,
    bool isParticipant,
    bool isHost,
    TaskProvider taskProvider,
  ) {
    return Column(
      children: [
        if (!isParticipant)
          ElevatedButton(
            onPressed: () => _joinTask(context, task),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Join Task', style: TextStyle(fontSize: 18)),
          ),
        if (isParticipant && !isHost)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Center(
              child: Text(
                'You have already joined.\nWaiting for the host to start the task.',
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (isHost && !task.autoStart) const SizedBox(height: 12),
        if (isHost && !task.autoStart)
          ElevatedButton(
            onPressed: () async {
              final success = await taskProvider.startTask(task.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task started!')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to start task.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Start Task', style: TextStyle(fontSize: 18)),
          ),
        if (isHost && task.autoStart)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Center(
              child: Text(
                'Task will auto‑start when full.',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStartedActions(
      BuildContext context, TaskModel task, bool isParticipant) {
    return Column(
      children: [
        if (isParticipant)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VotingScreen(task: task),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Go to Voting', style: TextStyle(fontSize: 18)),
          ),
        if (!isParticipant)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Center(
              child: Text(
                'Voting is live!\nWatch and vote from the Feed.',
                style: TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletedActions(BuildContext context, TaskModel task) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'Task Completed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              const SizedBox(height: 8),
              if (task.winnerInfo != null)
                Text(
                  'Winner: ${task.winnerInfo!['userId']}\n₦${task.winnerInfo!['prizeAmount']}',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _viewResults(task, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text('View Results', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  void _shareTask(BuildContext context, TaskModel task) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  void _joinTask(BuildContext context, TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinTaskScreen(task: task),
      ),
    );
  }

  void _viewResults(TaskModel task, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(task: task),
      ),
    );
  }
}
