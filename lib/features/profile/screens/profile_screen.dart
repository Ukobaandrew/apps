// lib/features/profile/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskwin/features/auth/providers/auth_provider.dart';
import 'package:taskwin/features/profile/screens/settings_screen.dart';
import 'package:taskwin/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  List<QueryDocumentSnapshot> _createdTasks = [];
  List<QueryDocumentSnapshot> _joinedTasks = [];
  int _wins = 0;
  int _losses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userDoc = await FirebaseService.usersCollection.doc(uid).get();
      _userData = userDoc.data() as Map<String, dynamic>?;

      final created = await FirebaseService.tasksCollection
          .where('hostId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      _createdTasks = created.docs;

      final joined = await FirebaseService.tasksCollection
          .where('participantIds', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      _joinedTasks = joined.docs;

      int wins = 0;
      for (var doc in joined.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 2 &&
            data['winnerInfo'] != null &&
            data['winnerInfo']['userId'] == uid) {
          wins++;
        }
      }
      _wins = wins;
      _losses = _joinedTasks.length - wins;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // Profile picture upload
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final uid = FirebaseService.currentUser!.uid;
    final storageRef =
        FirebaseStorage.instance.ref().child('profile_pics').child('$uid.jpg');

    try {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(File(pickedFile.path));
      }
      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseService.usersCollection.doc(uid).update({
        'photoUrl': downloadUrl,
      });
      setState(() {
        _userData?['photoUrl'] = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
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

  String _statusString(int? statusIndex) {
    switch (statusIndex) {
      case 0:
        return 'Waiting';
      case 1:
        return 'Live';
      case 2:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int? statusIndex) {
    switch (statusIndex) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: Colors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile header with tappable avatar
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.orange.shade100,
                              backgroundImage: _userData?['photoUrl'] != null
                                  ? NetworkImage(_userData!['photoUrl'])
                                  : null,
                              child: _userData?['photoUrl'] == null
                                  ? Text(
                                      (_userData?['displayName'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 40,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userData?['displayName'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData?['email'] ??
                                _userData?['phoneNumber'] ??
                                '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                              'Wins', _wins.toString(), Colors.green),
                          _buildStatColumn(
                              'Losses', _losses.toString(), Colors.red),
                          _buildStatColumn('Joined',
                              _joinedTasks.length.toString(), Colors.blue),
                          _buildStatColumn('Created',
                              _createdTasks.length.toString(), Colors.orange),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Badges section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Badges',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge('Rookie', Icons.star, Colors.amber),
                              _buildBadge(
                                  'Creator', Icons.video_call, Colors.purple),
                              _buildBadge(
                                  'Voter', Icons.how_to_vote, Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Created tasks
                    _buildTaskList('Tasks Created', _createdTasks),
                    const SizedBox(height: 16),

                    // Joined tasks
                    _buildTaskList('Tasks Joined', _joinedTasks),
                    const SizedBox(height: 16),

                    // Logout button
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(String title, List<QueryDocumentSnapshot> tasks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : Column(
                  children: tasks.take(3).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final taskId = doc.id;
                    final category = data['category'] ?? 'Fun';
                    final status = data['status'] as int?;
                    final prizePool =
                        (data['prizePool'] as num?)?.toDouble() ?? 0;
                    final stake =
                        (data['stakeAmount'] as num?)?.toDouble() ?? 0;
                    final participants =
                        (data['currentParticipants'] as int?) ?? 0;
                    final maxParticipants =
                        (data['maxParticipants'] as int?) ?? 50;
                    final endTime = (data['endTime'] as Timestamp?)?.toDate();

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/task-details',
                          arguments: taskId,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        _getCategoryImageUrl(category)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                height: 120,
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
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              data['title'] ?? 'Untitled',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
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
                                              color: _statusColor(status)
                                                  .withOpacity(0.9),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _statusString(status),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
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
                                              color: Colors.white70, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$participants/$maxParticipants',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.attach_money,
                                              color: Colors.white70, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '₦$stake',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11),
                                          ),
                                          const Spacer(),
                                          if (endTime != null)
                                            Text(
                                              'Ends ${DateFormat.MMMd().format(endTime)}',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11),
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
                      ),
                    );
                  }).toList(),
                ),
          if (tasks.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to full list
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                child: Text('View all (${tasks.length})'),
              ),
            ),
        ],
      ),
    );
  }
}
