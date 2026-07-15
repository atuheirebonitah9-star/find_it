import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, voice }

class MessageModel {
  final String id;
  final String text;
  final String senderUid;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? voiceUrl;
  final int? voiceDuration;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.voiceUrl,
    this.voiceDuration,
  });

  // Convert from Firestore document to Model
  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      // Get message type
      final typeString = data['type'] as String? ?? 'text';
      final type = typeString == 'voice' ? MessageType.voice : MessageType.text;

      return MessageModel(
        id: id,
        text: data['text'] as String? ?? '',
        senderUid: data['senderUid'] as String? ?? '',
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: data['isRead'] as bool? ?? false,
        type: type,
        voiceUrl: data['voiceUrl'] as String?,
        voiceDuration: data['voiceDuration'] as int?,
      );
    } catch (e) {
      print('Error parsing MessageModel: $e');
      return MessageModel(
        id: id,
        text: '',
        senderUid: '',
        timestamp: DateTime.now(),
        isRead: false,
        type: MessageType.text,
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
      'type': type.name,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
    };
  }
}