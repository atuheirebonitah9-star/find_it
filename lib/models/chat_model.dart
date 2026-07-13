import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String itemName;
  final String finderUid;
  final String ownerUid;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isActive;

  ChatModel({
    required this.chatId,
    required this.itemName,
    required this.finderUid,
    required this.ownerUid,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isActive = true,
  });

  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return ChatModel(
        chatId: id,
        itemName: data['itemName'] as String? ?? 'Lost Item',
        finderUid: data['finderUid'] as String? ?? '',
        ownerUid: data['ownerUid'] as String? ?? '',
        lastMessage: data['lastMessage'] as String? ?? 'No messages yet',
        lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data['isActive'] as bool? ?? true,
      );
    } catch (e) {
      print('Error parsing ChatModel: $e');
      return ChatModel(
        chatId: id,
        itemName: 'Lost Item',
        finderUid: '',
        ownerUid: '',
        lastMessage: 'No messages yet',
        lastMessageTime: DateTime.now(),
        isActive: true,
      );
    }
  }
}