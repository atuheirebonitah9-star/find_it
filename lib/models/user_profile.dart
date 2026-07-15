class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String studentId;
  final String? regNumber;
  final String course;
  final String? photoUrl;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    this.regNumber,
    required this.course,
    this.photoUrl,
    required this.createdAt,
});

Map<String, dynamic> toMap() =>{
    'fullName': fullName,
    'email': email,
    'studentId': studentId,
    'regNumber': regNumber,
    'course': course,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
};

factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
  return UserProfile(
    uid: uid,
    fullName: map['fullName'] ?? '',
    email: map['email'] ?? '',
    studentId: map['studentId'] ?? '',
    regNumber: map['regNumber'] ?? '',
    course: map['course'] ?? '',
    photoUrl: map['photoUrl'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );
}
}