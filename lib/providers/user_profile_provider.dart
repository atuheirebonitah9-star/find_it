import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _profileImageUrl;
  String? _displayName;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<User?>? _authSubscription;

  String? get profileImageUrl => _profileImageUrl;
  String? get displayName => _displayName;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProfileProvider() {
    // Listen to auth state changes so profile always reflects current user.
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _clearProfile();
      } else {
        _loadProfile(user);
      }
    });
  }

  /// Load profile for the given [user] from Firestore.
  Future<void> _loadProfile(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _profileImageUrl = (_userData?['photoUrl'] as String?) ?? '';
        _displayName = (_userData?['fullName'] as String?)?.isNotEmpty == true
            ? _userData!['fullName'] as String
            : user.displayName ?? user.email?.split('@').first ?? 'User';
      } else {
        await _createUserDocument(user);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('UserProfileProvider: error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a Firestore user document for first-time users.
  Future<void> _createUserDocument(User user) async {
    try {
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': user.displayName ?? user.email?.split('@').first ?? 'User',
        'photoUrl': '',
        'studentId': '',
        'regNumber': '',
        'course': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(user.uid).set(data);
      _userData = data;
      _profileImageUrl = '';
      _displayName = data['fullName'] as String;
      notifyListeners();
    } catch (e) {
      debugPrint('UserProfileProvider: error creating user document: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Refresh profile data from Firestore.
  Future<void> refreshProfile() async {
    final user = _auth.currentUser;
    if (user != null) await _loadProfile(user);
  }

  /// Updates the profile image URL in Firestore and locally.
  Future<void> updateProfileImage(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _profileImageUrl = imageUrl;
      _userData ??= {};
      _userData!['photoUrl'] = imageUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('UserProfileProvider: error updating profile image: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Fetch the profile image URL for any user by UID (one-time read).
  Future<String?> getProfileImageUrlForUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['photoUrl'] as String?) ?? '';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream the profile image URL for any user in real time.
  Stream<String?> streamProfileImageUrlForUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return (doc.data()?['photoUrl'] as String?) ?? '';
      }
      return null;
    });
  }

  /// Stream the full Firestore document for any user in real time.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Returns the cached profile image URL for the current user.
  String? getCurrentUserProfileImage() => _profileImageUrl;

  /// Clears all cached profile data (called on sign-out).
  void _clearProfile() {
    _profileImageUrl = null;
    _displayName = null;
    _userData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
