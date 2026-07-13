import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderUid;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.timestamp,
    this.isRead = false,
  });

  // Convert from Firestore document to Model
  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return MessageModel(
        id: id,
        text: data['text'] as String? ?? '',
        senderUid: data['senderUid'] as String? ?? '',
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: data['isRead'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing MessageModel: $e');
      return MessageModel(
        id: id,
        text: '',
        senderUid: '',
        timestamp: DateTime.now(),
        isRead: false,
      );
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderUid': senderUid,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}