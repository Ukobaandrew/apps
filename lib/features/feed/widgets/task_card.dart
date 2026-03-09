import 'package:flutter/material.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/widgets/countdown_timer.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isFullScreen;
  final VoidCallback onVote;
  final VoidCallback onShare;

  const TaskCard({
    super.key,
    required this.task,
    this.isFullScreen = false,
    required this.onVote,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and prize
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₦${task.prizePool.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Media preview placeholder (can be replaced with actual image/video)
          if (task.entryType == 'Photo' || task.entryType == 'Video')
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  task.entryType == 'Video' ? Icons.videocam : Icons.photo,
                  size: 50,
                  color: Colors.grey[600],
                ),
              ),
            ),
          // Description
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Footer: participants, timer, actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Participants count
                Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text('${task.currentParticipants}/${task.maxParticipants}'),
                  ],
                ),
                const SizedBox(width: 16),
                // Timer
                if (task.endTime != null)
                  Expanded(
                    child: CountdownTimer(endTime: task.endTime!),
                  ),
                // Vote and share buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: onVote,
                      tooltip: 'Vote',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: onShare,
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
