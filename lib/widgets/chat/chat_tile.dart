import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../services/chat_service.dart';

class ChatTile extends StatefulWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  final ChatService _chatService = ChatService();
  UserProfile? _otherUserProfile;
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final otherUserUid = _chatService.getOtherUserUid(widget.chat.finderUid, widget.chat.ownerUid);
    final profile = await _chatService.getUserProfile(otherUserUid);
    final unreadCount = await _chatService.getUnreadCount(widget.chat.chatId);
    if (mounted) {
      setState(() {
        _otherUserProfile = profile;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: const Icon(Icons.person, color: Colors.blue),
      ),
      title: Text(
        _isLoading ? 'Loading...' : _otherUserProfile?.fullName ?? widget.chat.itemName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        widget.chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('h:mm a').format(widget.chat.lastMessageTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          // Unread count indicator
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: widget.onTap,
    );
  }
}
