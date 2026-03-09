import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/features/tasks/providers/task_provider.dart';
import 'package:taskwin/services/firebase_service.dart';
import 'package:taskwin/features/tasks/widgets/countdown_timer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class JoinTaskScreen extends StatefulWidget {
  final TaskModel task;

  const JoinTaskScreen({super.key, required this.task});

  @override
  State<JoinTaskScreen> createState() => _JoinTaskScreenState();
}

class _JoinTaskScreenState extends State<JoinTaskScreen> {
  XFile? _entryFile;
  Uint8List? _imageBytes; // Store bytes for all platforms
  bool _isUploading = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final userId = FirebaseService.currentUser!.uid;
    setState(() {
      _hasJoined = widget.task.participantIds.contains(userId);
    });
  }

  Future<void> _pickEntry() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Read bytes for all platforms to avoid file path issues on Android
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _entryFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_entryFile == null) return;

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseService.currentUser!.uid;
      print('🟡 Starting upload for task ${widget.task.id}');

      final downloadUrl = await FirebaseService.uploadMedia(
        file: _entryFile!,
        userId: userId,
        taskId: widget.task.id,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Upload timed out after 60 seconds');
        },
      );

      print('🟢 Upload successful, URL: $downloadUrl');

      await FirebaseService.entriesCollection.add({
        'taskId': widget.task.id,
        'userId': userId,
        'mediaUrl': downloadUrl,
        'voteCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final joinSuccess = await taskProvider.joinTask(
        widget.task.id,
        userId,
        skipEntryCreation: true,
      );

      if (!joinSuccess) {
        throw Exception('Failed to join task after upload');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DETAILS',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: SelectableText(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Prepare Entry',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            _getCategoryImageUrl(widget.task.category)),
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
                          Text(
                            widget.task.title,
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
                            '₦${widget.task.stakeAmount} entry',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.task.currentParticipants}/${widget.task.maxParticipants} joined',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const Spacer(),
                              if (widget.task.startTime != null)
                                CountdownTimer(
                                  endTime: widget.task.startTime!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: _entryFile == null
                    ? _buildUploadPrompt()
                    : _buildPreviewAndSubmit(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.task.entryType == 'Video' ? Icons.videocam : Icons.photo,
              size: 50,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload your ${widget.task.entryType.toLowerCase()} entry',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show your skills and win!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickEntry,
            icon: const Icon(Icons.upload),
            label: const Text('Choose File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewAndSubmit() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              color: Colors.grey.shade100,
              child: Center(
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Text('Loading preview...')),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitEntry,
                icon: const Icon(Icons.check),
                label: Text(_isUploading ? 'Uploading...' : 'Submit Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickEntry,
                icon: const Icon(Icons.edit),
                label: const Text('Change File'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
