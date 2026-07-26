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

  String? get profileImageUrl => _profileImageUrl;
  String? get displayName => _displayName;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProfileProvider() {
    _loadProfile();
  }

  /// Load current user profile from Firestore
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _profileImageUrl = _userData?['photoUrl'] ?? '';
        _displayName = _userData?['fullName'] ?? user.displayName ?? user.email?.split('@').first ?? 'User';
      } else {
        await _createUserDocument(user);
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create user document when user first signs up
  Future<void> _createUserDocument(User user) async {
    try {
      final data = {
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
      _displayName = data['fullName'] as String? ?? 'User';
      notifyListeners();
    } catch (e) {
      print('Error creating user document: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  /// Update profile image URL (called after upload)
  Future<void> updateProfileImage(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _profileImageUrl = imageUrl;
      if (_userData != null) {
        _userData!['photoUrl'] = imageUrl;
      } else {
        _userData = {'photoUrl': imageUrl};
      }
      notifyListeners();
    } catch (e) {
      print('Error updating profile image: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Get profile image URL for ANY user (for chat screen)
  Future<String?> getProfileImageUrlForUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['photoUrl'] ?? '';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream profile image URL for ANY user (real-time updates)
  Stream<String?> streamProfileImageUrlForUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data()?['photoUrl'] as String? ?? '';
      }
      return null;
    });
  }

  /// Stream full user profile for ANY user (real-time updates)
  Stream<DocumentSnapshot> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get current user's profile image URL (cached)
  String? getCurrentUserProfileImage() {
    return _profileImageUrl;
  }

  /// Clear profile data (for sign out)
  void clearProfile() {
    _profileImageUrl = null;
    _displayName = null;
    _userData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}