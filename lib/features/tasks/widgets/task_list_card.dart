import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/models/task_status.dart' show TaskStatus;
import 'package:taskwin/features/tasks/widgets/countdown_timer.dart';

class TaskListCard extends StatelessWidget {
  final TaskModel task;

  const TaskListCard({super.key, required this.task});

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

  Color _getStatusColor() {
    switch (task.status) {
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

  String _getStatusText() {
    switch (task.status) {
      case TaskStatus.waiting:
        return 'Waiting';
      case TaskStatus.started:
        return 'Live';
      case TaskStatus.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/task-details', arguments: task.id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image
            Container(
              height: 160,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_getCategoryImageUrl(task.category)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Dark overlay
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Title and prize
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(),
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
                    // Description
                    Text(
                      task.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${task.currentParticipants}/${task.maxParticipants}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.attach_money,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '₦${task.stakeAmount}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const Spacer(),
                        if (task.status == TaskStatus.started &&
                            task.endTime != null)
                          CountdownTimer(
                            endTime: task.endTime!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (task.status == TaskStatus.waiting &&
                            task.startTime != null)
                          Text(
                            'Starts ${DateFormat.MMMd().format(task.startTime!)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
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
    );
  }
}
