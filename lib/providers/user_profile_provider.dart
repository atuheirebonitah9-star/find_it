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

  String? get profileImageUrl => _profileImageUrl;
  String? get displayName => _displayName;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

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
        _profileImageUrl = _userData?['profileImageUrl'];
        _displayName = _userData?['displayName'] ?? user.displayName;
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument(user);
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create user document if it doesn't exist
  Future<void> _createUserDocument(User user) async {
    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'profileImageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(user.uid).set(data);
    _userData = data;
    _profileImageUrl = '';
    _displayName = user.displayName;
    notifyListeners();
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  /// Get profile image URL for ANY user (for chat screen)
  Future<String?> getProfileImageUrlForUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['profileImageUrl'];
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
        .map((doc) => doc.data()?['profileImageUrl'] as String?);
  }

  /// Stream full user profile for ANY user (real-time updates)
  Stream<DocumentSnapshot> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get current user's profile image URL (cached)
  String? getCurrentUserProfileImage() {
    return _profileImageUrl;
  }
}