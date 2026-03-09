import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskwin/features/tasks/providers/task_provider.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';
import 'package:taskwin/core/constants.dart';
import 'package:taskwin/features/tasks/models/task_status.dart';
import 'package:taskwin/services/firebase_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stakeController = TextEditingController(text: '1000');
  final _maxParticipantsController = TextEditingController(text: '50');
  String _selectedCategory = AppConstants.categories[1];
  String _selectedEntryType = AppConstants.entryTypes[0];
  bool _autoStart = false;
  bool _isTemplate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stakeController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to create a task')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      final task = TaskModel(
        id: '',
        hostId: currentUser.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        stakeAmount: double.parse(_stakeController.text),
        minParticipants: 2,
        maxParticipants: int.parse(_maxParticipantsController.text),
        currentParticipants: 0,
        status: TaskStatus.waiting,
        entryType: _selectedEntryType,
        createdAt: DateTime.now(),
        votingDurationHours: 24,
        prizePool: 0,
        participantIds: [],
        autoStart: _autoStart,
      );

      try {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final success = await taskProvider.createTask(
          task,
          isTemplate: _isTemplate,
          autoStart: _autoStart,
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
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
          'Create Task',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main details card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'e.g., Water Chugging Contest',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon:
                              const Icon(Icons.title, color: Colors.orange),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the task rules...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description,
                              color: Colors.orange),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon:
                              const Icon(Icons.category, color: Colors.orange),
                        ),
                        items: AppConstants.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                      const SizedBox(height: 16),

                      // Entry type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedEntryType,
                        decoration: InputDecoration(
                          labelText: 'Entry Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            _selectedEntryType == 'Video'
                                ? Icons.videocam
                                : Icons.photo,
                            color: Colors.orange,
                          ),
                        ),
                        items: AppConstants.entryTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedEntryType = value!),
                      ),
                      const SizedBox(height: 16),

                      // Stake amount and max participants row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stakeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Entry Fee',
                                hintText: '₦1000',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    "₦",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Enter amount';
                                if (double.tryParse(value) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxParticipantsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Max Participants',
                                hintText: '50',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.people,
                                    color: Colors.orange),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Enter max participants';
                                if (int.tryParse(value) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Options card (auto-start + template)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Auto-start when full'),
                        subtitle: const Text(
                          'Task starts automatically when max participants join',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _autoStart,
                        activeColor: Colors.orange,
                        onChanged: (value) =>
                            setState(() => _autoStart = value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Save as Template'),
                        subtitle: const Text(
                          'Save this setup for future tasks',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isTemplate,
                        activeColor: Colors.orange,
                        onChanged: (value) =>
                            setState(() => _isTemplate = value),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Task',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optional helper for category image (if you add a header)
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
}
