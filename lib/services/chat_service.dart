import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_profile.dart';
import 'notification_event_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationEventService _eventService = NotificationEventService();

  String? get currentUserUid => _auth.currentUser?.uid;

  String generateChatId(String uid1, String uid2) {
    List<String> sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  String? _getAuthDisplayNameFor(String uid) {
    if (uid == _auth.currentUser?.uid) {
      final dn = _auth.currentUser?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
    }
    return null;
  }

  String _inferDisplayName(String uid) {
    if (uid == _auth.currentUser?.uid) {
      final dn = _auth.currentUser?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      final email = _auth.currentUser?.email?.trim();
      if (email != null && email.isNotEmpty) {
        return email.contains('@') ? email.split('@')[0] : email;
      }
    }
    return '';
  }

  Future<void> _ensureUserDocument(String uid, {String? fallbackName}) async {
    if (uid.trim().isEmpty) return;
    try {
      final doc = _firestore.collection('users').doc(uid);
      final snapshot = await doc.get();
      if (snapshot.exists) {
        final data = snapshot.data() ?? <String, dynamic>{};
        final existingName = (data['fullName'] as String?)?.trim() ?? '';
        if (existingName.isEmpty) {
          final authName = (uid == _auth.currentUser?.uid)
              ? _auth.currentUser?.displayName?.trim()
              : null;
          final bestName = (authName != null && authName.isNotEmpty)
              ? authName
              : (fallbackName ?? '').trim();
          if (bestName.isNotEmpty) {
            await doc.set(<String, dynamic>{
              'uid': uid,
              'email':
                  data['email'] ??
                  (uid == _auth.currentUser?.uid
                      ? _auth.currentUser?.email ?? ''
                      : ''),
              'fullName': bestName,
              'photoUrl':
                  data['photoUrl'] ??
                  (uid == _auth.currentUser?.uid
                      ? _auth.currentUser?.photoURL ?? ''
                      : ''),
              'studentId': data['studentId'] ?? '',
              'regNumber': data['regNumber'] ?? '',
              'course': data['course'] ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } else {
        final authName = (uid == _auth.currentUser?.uid)
            ? _auth.currentUser?.displayName?.trim()
            : null;
        final bestName = (authName != null && authName.isNotEmpty)
            ? authName
            : (fallbackName ?? '').trim();
        if (bestName.isNotEmpty) {
          await doc.set(<String, dynamic>{
            'uid': uid,
            'email': uid == _auth.currentUser?.uid
                ? _auth.currentUser?.email ?? ''
                : '',
            'fullName': bestName,
            'photoUrl': uid == _auth.currentUser?.uid
                ? _auth.currentUser?.photoURL ?? ''
                : '',
            'studentId': '',
            'regNumber': '',
            'course': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('ChatService: ensureUserDocument failed for $uid: $e');
    }
  }

  Future<String> createChat({
    required String finderUid,
    required String ownerUid,
    required String itemName,
  }) async {
    if (finderUid.trim().isEmpty || ownerUid.trim().isEmpty) {
      throw Exception('Both users must be provided to create a chat');
    }
    if (finderUid == ownerUid) {
      throw Exception('Cannot create a chat with yourself');
    }

    String chatId = generateChatId(finderUid, ownerUid);

    final chatRef = _firestore.collection('chats').doc(chatId);
    final doc = await chatRef.get();
    if (doc.exists) {
      await chatRef.set({
        'participants': FieldValue.arrayUnion([finderUid, ownerUid]),
        'isActive': true,
      }, SetOptions(merge: true));
      return chatId;
    }

    final finderNameFuture = getUserProfile(finderUid);
    final ownerNameFuture = getUserProfile(ownerUid);
    final results = await Future.wait([finderNameFuture, ownerNameFuture]);
    final finderProfile = results[0];
    final ownerProfile = results[1];

    final finderName = (finderProfile?.fullName.trim().isNotEmpty == true)
        ? finderProfile!.fullName.trim()
        : _inferDisplayName(finderUid);
    final ownerName = (ownerProfile?.fullName.trim().isNotEmpty == true)
        ? ownerProfile!.fullName.trim()
        : _inferDisplayName(ownerUid);

    await _firestore.collection('chats').doc(chatId).set({
      'finderUid': finderUid,
      'ownerUid': ownerUid,
      'participants': [finderUid, ownerUid],
      'itemName': itemName,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      if (finderName.isNotEmpty) 'finderName': finderName,
      if (ownerName.isNotEmpty) 'ownerName': ownerName,
    });

    if (finderName.isNotEmpty) {
      _ensureUserDocument(finderUid, fallbackName: finderName);
    }
    if (ownerName.isNotEmpty) {
      _ensureUserDocument(ownerUid, fallbackName: ownerName);
    }

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    if (currentUserUid == null) throw Exception('User not logged in');

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw Exception('Cannot send empty message');
    }

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final finderUid = chatData['finderUid'] as String? ?? '';
      final ownerUid = chatData['ownerUid'] as String? ?? '';
      final senderUid = currentUserUid!;

      final senderNameFromAuth = _getAuthDisplayNameFor(senderUid) ?? '';
      final senderPhotoFromAuth = (senderUid == _auth.currentUser?.uid)
          ? _auth.currentUser?.photoURL?.trim()
          : null;
      final senderPhotoUrl =
          (senderPhotoFromAuth != null && senderPhotoFromAuth.isNotEmpty)
          ? senderPhotoFromAuth
          : '';

      final batch = _firestore.batch();
      final now = Timestamp.now();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'text': trimmedText,
        'senderUid': senderUid,
        'timestamp': now,
        'isRead': false,
        'type': 'text',
        'senderName': senderNameFromAuth,
        'senderPhotoUrl': senderPhotoUrl,
      });

      final chatUpdate = <String, dynamic>{
        'lastMessage': trimmedText,
        'lastMessageTime': now,
        'participants': FieldValue.arrayUnion([finderUid, ownerUid]),
        'isActive': true,
      };
      if (senderNameFromAuth.isNotEmpty) {
        if (senderUid == finderUid) {
          chatUpdate['finderName'] = senderNameFromAuth;
        } else if (senderUid == ownerUid) {
          chatUpdate['ownerName'] = senderNameFromAuth;
        }
      }
      if (senderPhotoUrl.isNotEmpty) {
        if (senderUid == finderUid) {
          chatUpdate['finderPhotoUrl'] = senderPhotoUrl;
        } else if (senderUid == ownerUid) {
          chatUpdate['ownerPhotoUrl'] = senderPhotoUrl;
        }
      }

      batch.update(_firestore.collection('chats').doc(chatId), chatUpdate);

      await batch.commit();

      if (senderNameFromAuth.isNotEmpty) {
        _ensureUserDocument(senderUid, fallbackName: senderNameFromAuth);
      }

      final recipientUid = (finderUid == senderUid) ? ownerUid : finderUid;
      final itemName = chatData['itemName'] as String? ?? '';

      if (recipientUid.isNotEmpty && recipientUid != senderUid) {
        _eventService.emit(
          NotificationEvent(
            type: NotificationEventType.messageReceived,
            data: {
              'chatId': chatId,
              'senderUid': senderUid,
              'senderName': senderNameFromAuth,
              'text': trimmedText,
              'itemName': itemName,
            },
            targetUserId: recipientUid,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendVoiceMessage({
    required String chatId,
    required String voiceUrl,
    required int voiceDuration,
  }) async {
    if (currentUserUid == null) throw Exception('User not logged in');
    if (voiceUrl.trim().isEmpty) throw Exception('Voice URL cannot be empty');
    if (voiceDuration <= 0) throw Exception('Invalid voice duration');

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final finderUid = chatData['finderUid'] as String? ?? '';
      final ownerUid = chatData['ownerUid'] as String? ?? '';
      final senderUid = currentUserUid!;

      final senderNameFromAuth = _getAuthDisplayNameFor(senderUid) ?? '';
      final senderPhotoFromAuth = (senderUid == _auth.currentUser?.uid)
          ? _auth.currentUser?.photoURL?.trim()
          : null;
      final senderPhotoUrl =
          (senderPhotoFromAuth != null && senderPhotoFromAuth.isNotEmpty)
          ? senderPhotoFromAuth
          : '';

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final now = Timestamp.now();
      batch.set(messageRef, {
        'text': '',
        'senderUid': senderUid,
        'timestamp': now,
        'isRead': false,
        'type': 'voice',
        'voiceUrl': voiceUrl,
        'voiceDuration': voiceDuration,
        'senderName': senderNameFromAuth,
        'senderPhotoUrl': senderPhotoUrl,
      });

      final chatUpdate = <String, dynamic>{
        'lastMessage': 'Voice message',
        'lastMessageTime': now,
        'participants': FieldValue.arrayUnion([finderUid, ownerUid]),
        'isActive': true,
      };
      if (senderNameFromAuth.isNotEmpty) {
        if (senderUid == finderUid) {
          chatUpdate['finderName'] = senderNameFromAuth;
        } else if (senderUid == ownerUid) {
          chatUpdate['ownerName'] = senderNameFromAuth;
        }
      }
      if (senderPhotoUrl.isNotEmpty) {
        if (senderUid == finderUid) {
          chatUpdate['finderPhotoUrl'] = senderPhotoUrl;
        } else if (senderUid == ownerUid) {
          chatUpdate['ownerPhotoUrl'] = senderPhotoUrl;
        }
      }

      batch.update(_firestore.collection('chats').doc(chatId), chatUpdate);

      await batch.commit();

      if (senderNameFromAuth.isNotEmpty) {
        _ensureUserDocument(senderUid, fallbackName: senderNameFromAuth);
      }

      final recipientUid = (finderUid == senderUid) ? ownerUid : finderUid;
      final itemName = chatData['itemName'] as String? ?? '';

      if (recipientUid.isNotEmpty && recipientUid != senderUid) {
        _eventService.emit(
          NotificationEvent(
            type: NotificationEventType.messageReceived,
            data: {
              'chatId': chatId,
              'senderUid': senderUid,
              'senderName': senderNameFromAuth,
              'text': 'Voice message',
              'itemName': itemName,
            },
            targetUserId: recipientUid,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending voice message: $e');
      rethrow;
    }
  }

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

  Stream<List<ChatModel>> getUserChats() {
    if (currentUserUid == null) return Stream.value([]);
    final uid = currentUserUid!;

    return _firestore
        .collection('chats')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .where((doc) {
                final data = doc.data();
                final participants = data['participants'] as List<dynamic>?;
                if (participants != null && participants.isNotEmpty) {
                  return participants.contains(uid);
                }
                final finderUid = data['finderUid'] as String? ?? '';
                final ownerUid = data['ownerUid'] as String? ?? '';
                return finderUid == uid || ownerUid == uid;
              })
              .map((doc) {
                return ChatModel.fromFirestore(doc.data(), doc.id);
              })
              .toList();
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserUid == null) return;

    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderUid', isNotEqualTo: currentUserUid)
          .get();

      if (messages.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  String getOtherUserUid(String finderUid, String ownerUid) {
    return (finderUid == currentUserUid) ? ownerUid : finderUid;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        var profile = UserProfile.fromMap(uid, data);

        if (profile.fullName.trim().isEmpty && uid == currentUserUid) {
          final displayName = _auth.currentUser?.displayName;
          if (displayName != null && displayName.trim().isNotEmpty) {
            profile = UserProfile(
              uid: profile.uid,
              fullName: displayName,
              email: profile.email,
              studentId: profile.studentId,
              regNumber: profile.regNumber,
              course: profile.course,
              photoUrl: profile.photoUrl,
              createdAt: profile.createdAt,
              updatedAt: profile.updatedAt,
            );
          }
        }
        return profile;
      }

      if (uid == currentUserUid) {
        final authUser = _auth.currentUser;
        if (authUser != null) {
          final constructed = UserProfile(
            uid: uid,
            fullName: authUser.displayName ?? authUser.email ?? 'Unknown User',
            email: authUser.email ?? '',
            studentId: '',
            regNumber: '',
            course: '',
            photoUrl: authUser.photoURL,
            createdAt: DateTime.now(),
            updatedAt: null,
          );
          _ensureUserDocument(uid, fallbackName: constructed.fullName);
          return constructed;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<int> getUnreadCount(String chatId) async {
    if (currentUserUid == null) return 0;
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderUid', isNotEqualTo: currentUserUid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  Stream<int> getUnreadCountStream(String chatId) {
    if (currentUserUid == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderUid', isNotEqualTo: currentUserUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> archiveChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isActive': false,
    });
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }
}
