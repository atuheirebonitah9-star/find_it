import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  static const Color secondaryColor = Color(0xFF006A61);
  static const Color backgroundColor = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF45464D);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor.withOpacity(0.8),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _userProfile?.photoUrl != null
                            ? NetworkImage(_userProfile!.photoUrl!)
                            : null,
                        child: _userProfile?.photoUrl == null
                            ? const Icon(Icons.person_outline, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_userProfile != null) ...[
                      _buildInfoCard('Full Name', _userProfile!.fullName, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildInfoCard('Email', _userProfile!.email, Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildInfoCard('Student ID', _userProfile!.studentId, Icons.badge_outlined),
                      if (_userProfile!.regNumber != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard('Registration Number', _userProfile!.regNumber!, Icons.description_outlined),
                      ],
                      if (_userProfile!.course != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard('Course', _userProfile!.course!, Icons.school_outlined),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Text(
                          'No profile data found.',
                          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: secondaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: onSurface, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
