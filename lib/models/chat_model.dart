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
    return ChatModel(
      chatId: id,
      itemName: data['itemName'] ?? 'Lost Item',
      finderUid: data['finderUid'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      lastMessage: data['lastMessage'] ?? 'No messages yet',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}