import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists) {
          setState(() {
            _userProfile = UserProfile.fromMap(userId, doc.data()!);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadProfilePicture() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
      });

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: AppColors.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ============ PROFILE PICTURE ============
                    _buildProfilePicture(),
                    
                    const SizedBox(height: 24),
                    
                    if (_userProfile != null) ...[
                      // ============ PROFILE INFO CARDS ============
                      _buildInfoCard(
                        'Full Name',
                        _userProfile!.fullName,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Email',
                        _userProfile!.email,
                        Icons.email_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Student ID',
                        _userProfile!.studentId,
                        Icons.badge_outlined,
                      ),
                      if (_userProfile!.regNumber != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          'Registration Number',
                          _userProfile!.regNumber!,
                          Icons.description_outlined,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Course',
                        _userProfile!.course,
                        Icons.school_outlined,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // ============ SIGN OUT BUTTON ============
                      _buildSignOutButton(),
                    ] else ...[
                      _buildEmptyState(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // ============ PROFILE PICTURE ============
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.surface,
              backgroundImage: _userProfile?.photoUrl != null
                  ? NetworkImage(_userProfile!.photoUrl!)
                  : null,
              child: _userProfile?.photoUrl == null
                  ? Icon(
                      Icons.person_outline,
                      size: 56,
                      color: AppColors.muted,
                    )
                  : null,
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadProfilePicture,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ INFO CARD ============
  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: 0.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ SIGN OUT BUTTON ============
  Widget _buildSignOutButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _authService.signOut(),
        icon: Icon(
          Icons.logout_outlined,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorContainer,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ============ EMPTY STATE ============
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No profile data found.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}