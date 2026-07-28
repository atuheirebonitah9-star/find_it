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
    super.dispose();
  }

  String _getDisplayName() {
    if (_isLoadingProfile) return 'Loading...';
    final profileName = (_otherUserProfile?.fullName ?? '').trim();
    if (profileName.isNotEmpty) return profileName;

    final otherUserUid = _chatService.getOtherUserUid(
      widget.chat.finderUid,
      widget.chat.ownerUid,
    );
    final chatStoredName = widget.chat.nameForUser(otherUserUid)?.trim() ?? '';
    if (chatStoredName.isNotEmpty) return chatStoredName;

    final email = (_otherUserProfile?.email ?? '').trim();
    if (email.isNotEmpty) {
      return email.contains('@') ? email.split('@')[0] : email;
    }

    return 'Unknown User';
  }

  String _getAvatarInitial() {
    final displayName = _getDisplayName();
    if (_isLoadingProfile) return 'L';
    if (displayName.isEmpty || displayName == 'Unknown User') return '?';
    return displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();
    final isBold = _unreadCount > 0;
    final avatarInitial = _getAvatarInitial();
    final hasItemContext = widget.chat.itemName.trim().isNotEmpty;

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
                    backgroundColor: displayName == 'Unknown User'
                        ? AppColors.muted.withOpacity(0.18)
                        : AppColors.primary.withOpacity(0.12),
                    child: Text(
                      avatarInitial,
                      style: TextStyle(
                        color: displayName == 'Unknown User'
                            ? AppColors.muted
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight:
                                      isBold ? FontWeight.w700 : FontWeight.w600,
                                  color: AppColors.text,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (hasItemContext)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 11,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.chat.itemName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.chat.lastMessage.isEmpty
                                    ? 'No messages yet'
                                    : widget.chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isBold
                                      ? AppColors.text
                                      : AppColors.textSecondary,
                                  fontWeight: isBold
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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
