import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taskwin/services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // --- Email/Password Sign In ---
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      _ensureUserDocument(userCredential.user);
      _setLoading(false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _setError(_getFriendlyErrorMessage(e));
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Sign in failed. Please try again.');
      _setLoading(false);
      return null;
    }
  }

  // --- Email/Password Sign Up ---
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await _ensureUserDocument(userCredential.user);
      _setLoading(false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _setError(_getFriendlyErrorMessage(e));
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Sign up failed. Please try again.');
      _setLoading(false);
      return null;
    }
  }

  // --- Google Sign-In ---
  Future<UserCredential?> signInWithGoogle() async {
    _setError(null);
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserDocument(userCredential.user);
      _setLoading(false);
      return userCredential;
    } catch (e) {
      _setError('Google Sign-In failed. Please try again.');
      _setLoading(false);
      return null;
    }
  }

  // --- Ensure Firestore user document exists ---
  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;
    final userDoc = await FirebaseService.usersCollection.doc(user.uid).get();
    if (!userDoc.exists) {
      await FirebaseService.usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? (user.email ?? 'User'),
        'email': user.email,
        'photoUrl': user.photoURL ?? '',
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    _setLoading(true);
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    _setLoading(false);
  }

  // --- Helper: friendly error messages ---
  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
