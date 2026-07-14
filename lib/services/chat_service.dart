import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_profile.dart';

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
      'lastMessage': '',
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

  // Get other user's UID from chat
  String getOtherUserUid(String finderUid, String ownerUid) {
    return (finderUid == currentUserUid) ? ownerUid : finderUid;
  }

  // Get UserProfile for a user UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get unread message count for a chat
  Future<int> getUnreadCount(String chatId) async {
    if (currentUserUid == null) return 0;
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderUid', isNotEqualTo: currentUserUid)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Archive a chat
  Future<void> archiveChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isActive': false,
    });
  }

  // Delete a chat (permanently removes it from Firestore)
  Future<void> deleteChat(String chatId) async {
    // First delete all messages in the chat
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    
    for (var doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Then delete the chat document itself
    await _firestore.collection('chats').doc(chatId).delete();
  }
}