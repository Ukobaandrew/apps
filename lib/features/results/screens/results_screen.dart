import 'package:flutter/material.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/services/firebase_service.dart';

class ResultsScreen extends StatefulWidget {
  final TaskModel task;

  const ResultsScreen({super.key, required this.task});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final snapshot = await FirebaseService.entriesCollection
        .where('taskId', isEqualTo: widget.task.id)
        .orderBy('voteCount', descending: true)
        .get();

    setState(() {
      _leaderboard = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final winner = _leaderboard.isNotEmpty ? _leaderboard.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Winner Card
                  if (winner != null)
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              '🏆 WINNER 🏆',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 40,
                              child: Text(winner['userId'][0].toUpperCase()),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'User ${winner['userId'].substring(0, 8)}...',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Votes: ${winner['voteCount']}'),
                            const SizedBox(height: 8),
                            Text(
                              'Prize: ₦${widget.task.prizePool.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Leaderboard
                  const Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._leaderboard.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final data = entry.value;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('$index'),
                        ),
                        title: Text('User ${data['userId'].substring(0, 8)}...'),
                        trailing: Text('${data['voteCount']} votes'),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Share Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Share results
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Results'),
                  ),
                ],
              ),
            ),
    );
  }
}
