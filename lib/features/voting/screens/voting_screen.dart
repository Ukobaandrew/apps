import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/providers/task_provider.dart';
import 'package:taskwin/features/tasks/widgets/countdown_timer.dart';
import 'package:taskwin/features/voting/widgets/entry_card.dart';
import 'package:taskwin/services/firebase_service.dart';

class VotingScreen extends StatefulWidget {
  final TaskModel task;

  const VotingScreen({super.key, required this.task});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _hasVoted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _checkIfVoted();
  }

  Future<void> _loadEntries() async {
    try {
      final snapshot = await FirebaseService.entriesCollection
          .where('taskId', isEqualTo: widget.task.id)
          .orderBy('voteCount', descending: true)
          .get();

      setState(() {
        _entries = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, ...data};
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading entries: $e')),
      );
    }
  }

  Future<void> _checkIfVoted() async {
    final userId = FirebaseService.currentUser!.uid;
    final voteSnapshot = await FirebaseService.votesCollection
        .where('taskId', isEqualTo: widget.task.id)
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      _hasVoted = voteSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _castVote(String entryId) async {
    if (_hasVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already voted in this task')),
      );
      return;
    }

    final provider = Provider.of<TaskProvider>(context, listen: false);
    try {
      await provider.submitVote(
          widget.task.id, entryId, FirebaseService.currentUser!.uid);
      setState(() => _hasVoted = true);
      _loadEntries(); // refresh vote counts
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVotingActive = widget.task.endTime != null &&
        widget.task.endTime!.isAfter(DateTime.now()) &&
        !_hasVoted;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.task.title,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_entries.length} ${_entries.length == 1 ? 'Entry' : 'Entries'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                if (widget.task.endTime != null)
                  CountdownTimer(
                    endTime: widget.task.endTime!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No entries yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to submit your entry!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEntries,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EntryCard(
                          entry: entry,
                          onVote: () => _castVote(entry['id']),
                          isVotable: isVotingActive,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
