import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentUserUid => _chatService.currentUserUid;

  // Load user's chats
  void loadChats() {
    _isLoading = true;
    notifyListeners();

    _chatService.getUserChats().listen(
      (chatList) {
        print('Chats loaded: ${chatList.length}');
        _chats = chatList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading chats: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load messages for a specific chat
  void loadMessages(String chatId) {
    _isLoading = true;
    notifyListeners();

    _chatService.getMessages(chatId).listen(
      (messageList) {
        print('Messages loaded: ${messageList.length}');
        _messages = messageList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading messages: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Send message
  Future<void> sendMessage(String chatId, String text) async {
    await _chatService.sendMessage(chatId: chatId, text: text);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    await _chatService.markMessagesAsRead(chatId);
  }

  // Archive chat
  Future<void> archiveChat(String chatId) async {
    await _chatService.archiveChat(chatId);
    _chats.removeWhere((chat) => chat.chatId == chatId);
    notifyListeners();
  }

  // Create new chat
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

  // Clear messages
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}