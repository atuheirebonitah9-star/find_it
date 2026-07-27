import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';

class ChatTile extends StatefulWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.chat, required this.onTap});

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  final ChatService _chatService = ChatService();
  UserProfile? _otherUserProfile;
  int _unreadCount = 0;
  bool _isLoadingProfile = true;
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ChatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.chatId != widget.chat.chatId) {
      _unreadSubscription?.cancel();
      _unreadSubscription = null;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final otherUserUid = _chatService.getOtherUserUid(
      widget.chat.finderUid,
      widget.chat.ownerUid,
    );

    final profile = await _chatService.getUserProfile(otherUserUid);
    if (mounted) {
      setState(() {
        _otherUserProfile = profile;
        _isLoadingProfile = false;
      });
    }

    _unreadSubscription?.cancel();
    _unreadSubscription = _chatService
        .getUnreadCountStream(widget.chat.chatId)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _isLoadingProfile
        ? 'Loading...'
        : _otherUserProfile?.fullName ?? widget.chat.itemName;
    final isBold = _unreadCount > 0;

    String initial = 'U';
    if (!_isLoadingProfile &&
        _otherUserProfile != null &&
        _otherUserProfile!.fullName.isNotEmpty) {
      initial = _otherUserProfile!.fullName[0].toUpperCase();
    } else if (widget.chat.itemName.isNotEmpty) {
      initial = widget.chat.itemName[0].toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.text,
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.chat.lastMessage.isEmpty
                              ? 'No messages yet'
                              : widget.chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isBold ? AppColors.text : AppColors.textSecondary,
                            fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(widget.chat.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          constraints: const BoxConstraints(minWidth: 22),
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
