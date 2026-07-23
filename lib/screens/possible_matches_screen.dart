import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../matching_logic.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'chat/chat_screen.dart';

class PossibleMatchesScreen extends StatelessWidget {
  final List<MatchDocument> matches;

  const PossibleMatchesScreen({super.key, required this.matches});

  Future<void> _openChat(BuildContext context, MatchDocument match) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatId = await chatProvider.createChat(
      finderUid: FirebaseAuth.instance.currentUser?.uid ?? '',
      ownerUid: match.report.userId ?? '',
      itemName: match.report.itemName,
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserUid: match.report.userId ?? '',
            itemName: match.report.itemName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Possible Matches'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: matches.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No matches found yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchCard(context, match);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchDocument match) {
    return _HoverableMatchCard(
      match: match,
      onChat: () => _openChat(context, match),
    );
  }
}

class _HoverableMatchCard extends StatefulWidget {
  final MatchDocument match;
  final VoidCallback onChat;

  const _HoverableMatchCard({required this.match, required this.onChat});

  @override
  State<_HoverableMatchCard> createState() => _HoverableMatchCardState();
}

class _HoverableMatchCardState extends State<_HoverableMatchCard> {
  bool _hovered = false;

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()
          ..scaleByDouble(
            _hovered ? 1.01 : 1.0,
            _hovered ? 1.01 : 1.0,
            1.0,
            1.0,
          ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.06),
              blurRadius: _hovered ? 16 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    match.report.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Category', match.report.category),
            _infoRow('Location', match.report.location),
            _infoRow(
              'Date',
              '${match.report.date.month}/${match.report.date.day}/${match.report.date.year}',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat about this item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
