import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user UID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Generate Chat ID (sorted to be consistent)
  String generateChatId(String uid1, String uid2) {
    List<String> sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Create a new chat
  Future<String> createChat({
    required String finderUid,
    required String ownerUid,
    required String itemName,
  }) async {
    String chatId = generateChatId(finderUid, ownerUid);
    
    // Check if chat already exists
    DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return chatId; // Chat exists, return ID
    }

    // Create new chat document
    await _firestore.collection('chats').doc(chatId).set({
      'finderUid': finderUid,
      'ownerUid': ownerUid,
      'itemName': itemName,
      'lastMessage': 'Chat started',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatId;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    if (currentUserUid == null) throw Exception('User not logged in');

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderUid': currentUserUid,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats() {
    if (currentUserUid == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .where((doc) {
            // Only show chats where user is either finder or owner
            String finderUid = doc.data()['finderUid'] ?? '';
            String ownerUid = doc.data()['ownerUid'] ?? '';
            return finderUid == currentUserUid || ownerUid == currentUserUid;
          })
          .map((doc) {
            return ChatModel.fromFirestore(doc.data(), doc.id);
          }).toList();
      
      // Sort chats by lastMessageTime on client to avoid needing composite index
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserUid == null) return;

    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderUid', isNotEqualTo: currentUserUid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get other user's info from chat
  Future<Map<String, dynamic>> getOtherUserInfo(String chatId) async {
    DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    String finderUid = data['finderUid'] ?? '';
    String ownerUid = data['ownerUid'] ?? '';
    String otherUid = (finderUid == currentUserUid) ? ownerUid : finderUid;

    // Get user details from users collection (assumes you have a users collection)
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherUid).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  // Delete/Archive a chat
  Future<void> archiveChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isActive': false,
    });
  }
}