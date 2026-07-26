import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String studentId;
  final String regNumber;
  final String course;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.regNumber,
    required this.course,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'studentId': studentId,
      'regNumber': regNumber,
      'course': course,
      'photoUrl': photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      regNumber: map['regNumber'] ?? '',
      course: map['course'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserProfile.create({
    required String uid,
    required String fullName,
    required String email,
    required String studentId,
    required String regNumber,
    required String course,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName,
      email: email,
      studentId: studentId,
      regNumber: regNumber,
      course: course,
      photoUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}