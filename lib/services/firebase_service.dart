import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // for XFile
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseStorage get storage => _storage;

  static CollectionReference get usersCollection =>
      _firestore.collection('users');
  static CollectionReference get tasksCollection =>
      _firestore.collection('tasks');
  static CollectionReference get entriesCollection =>
      _firestore.collection('entries');
  static CollectionReference get votesCollection =>
      _firestore.collection('votes');
  static CollectionReference get transactionsCollection =>
      _firestore.collection('transactions');

  static User? get currentUser => _auth.currentUser;

  static Future<String> uploadMedia({
    required XFile file,
    required String userId,
    required String taskId,
  }) async {
    print('🟡 uploadMedia: started');
    final ref = _storage
        .ref()
        .child('entries')
        .child(userId)
        .child(taskId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    if (kIsWeb) {
      print('🟡 uploadMedia: reading bytes...');
      final bytes = await file.readAsBytes();
      print('🟡 uploadMedia: bytes read, size = ${bytes.length}');
      await ref.putData(bytes);
      print('🟡 uploadMedia: putData completed');
    } else {
      final fileIO = File(file.path);
      await ref.putFile(fileIO);
    }
    final url = await ref.getDownloadURL();
    print('🟢 uploadMedia: URL = $url');
    return url;
  }

  static Future<void> updateWalletBalance({
    required String userId,
    required double amount,
    required String type,
    required String description,
  }) async {
    final userRef = usersCollection.doc(userId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(userRef);
      final current = (doc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      tx.update(userRef, {'balance': current + amount});
      await transactionsCollection.add({
        'userId': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'balanceAfter': current + amount,
      });
    });
  }
}
