import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;

  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentUserUid => _chatService.currentUserUid;
  String? get currentChatId => _currentChatId;

  void loadChats() {
    _chatsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _chatsSubscription = _chatService.getUserChats().listen(
      (chatList) {
        debugPrint('Chats loaded: ${chatList.length}');
        _chats = chatList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading chats: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void loadMessages(String chatId) {
    if (_currentChatId == chatId && _messagesSubscription != null) {
      return;
    }

    _messagesSubscription?.cancel();
    _messages = [];
    _currentChatId = chatId;
    _isLoading = true;
    notifyListeners();

    _messagesSubscription = _chatService.getMessages(chatId).listen(
      (messageList) {
        debugPrint('Messages loaded: ${messageList.length}');
        _messages = messageList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading messages: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> sendMessage(String chatId, String text) async {
    try {
      await _chatService.sendMessage(chatId: chatId, text: text);
    } catch (e) {
      debugPrint('Error in provider sendMessage: $e');
      rethrow;
    }
  }

  Future<void> sendVoiceMessage(
    String chatId,
    String voiceUrl,
    int voiceDuration,
  ) async {
    try {
      await _chatService.sendVoiceMessage(
        chatId: chatId,
        voiceUrl: voiceUrl,
        voiceDuration: voiceDuration,
      );
    } catch (e) {
      debugPrint('Error in provider sendVoiceMessage: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    await _chatService.markMessagesAsRead(chatId);
  }

  Future<void> archiveChat(String chatId) async {
    await _chatService.archiveChat(chatId);
    _chats.removeWhere((chat) => chat.chatId == chatId);
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    await _chatService.deleteChat(chatId);
    _chats.removeWhere((chat) => chat.chatId == chatId);
    if (_currentChatId == chatId) {
      clearMessages();
    }
    notifyListeners();
  }

  Future<String> createChat({
    required String finderUid,
    required String ownerUid,
    required String itemName,
  }) async {
    return await _chatService.createChat(
      finderUid: finderUid,
      ownerUid: ownerUid,
      itemName: itemName,
    );
  }

  void clearMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _messages = [];
    _currentChatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _chatsSubscription = null;
    _messagesSubscription = null;
    super.dispose();
  }
}
