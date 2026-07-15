import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input_field.dart';
import '../../services/chat_service.dart';
import '../../models/user_profile.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserUid;
  final String itemName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserUid,
    required this.itemName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  UserProfile? _otherUserProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    // Load messages, mark as read, and load other user profile when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.chatId);
      chatProvider.markMessagesAsRead(widget.chatId);
      _loadOtherUserProfile();
    });
  }

  Future<void> _loadOtherUserProfile() async {
    final profile = await _chatService.getUserProfile(widget.otherUserUid);
    if (mounted) {
      setState(() {
        _otherUserProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingProfile ? 'Loading...' : _otherUserProfile?.fullName ?? 'User',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Item: ${widget.itemName}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when messages are loaded/updated
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = message.senderUid == chatProvider.currentUserUid;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          MessageInputField(
            onSend: (text) async {
              await Provider.of<ChatProvider>(context, listen: false)
                  .sendMessage(widget.chatId, text);
              _scrollToBottom();
            },
            onSendVoice: (voiceUrl, duration) async {
              await Provider.of<ChatProvider>(context, listen: false)
                  .sendVoiceMessage(widget.chatId, voiceUrl, duration);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.orange),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.blue),
                title: const Text('Archive Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveChat();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteChatDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to permanently delete this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _deleteChat();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteChat() async {
    await Provider.of<ChatProvider>(context, listen: false)
        .deleteChat(widget.chatId);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully')),
      );
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report User'),
          content: const Text('Are you sure you want to report this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User reported successfully')),
                );
              },
              child: const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: const Text('Are you sure you want to block this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked successfully')),
                );
              },
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _archiveChat() async {
    await Provider.of<ChatProvider>(context, listen: false)
        .archiveChat(widget.chatId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat archived')),
    );
  }
}