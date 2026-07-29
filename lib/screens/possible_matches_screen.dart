import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../matching_logic.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'chat/chat_screen.dart';
import 'item_details_screen.dart';

class PossibleMatchesScreen extends StatelessWidget {
  final List<MatchDocument> matches;

  const PossibleMatchesScreen({super.key, required this.matches});

  Future<void> _openChat(BuildContext context, MatchDocument match) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final matchUserUid = match.report.userId;

      if (currentUserUid == null || matchUserUid == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not identify users for chat'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final bool isMatchLost = match.report.isLost ?? false;

      final String finderUid;
      final String ownerUid;

      if (isMatchLost) {
        finderUid = currentUserUid;
        ownerUid = matchUserUid;
      } else {
        finderUid = matchUserUid;
        ownerUid = currentUserUid;
      }

      final chatId = await chatProvider.createChat(
        finderUid: finderUid,
        ownerUid: ownerUid,
        itemName: match.report.itemName,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserUid: matchUserUid,
              itemName: match.report.itemName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openDetails(BuildContext context, MatchDocument match) {
    final data = <String, dynamic>{
      'itemName': match.report.itemName,
      'category': match.report.category,
      'location': match.report.location,
      'description': match.report.description,
      'status': match.report.isLost == true ? 'lost' : 'found',
      'userId': match.report.userId,
      'date': Timestamp.fromDate(match.report.date),
      if (match.report.imageUrl != null) 'imageUrl': match.report.imageUrl,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          itemId: match.report.userId ?? '',
          data: data,
          chatId: resolvedChatId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // REMOVE DUPLICATES - Keep only unique matches based on userId + itemName
    final uniqueMatches = <MatchDocument>[];
    final seen = <String>{};
    
    for (var match in matches) {
      final key = '${match.report.userId}_${match.report.itemName}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueMatches.add(match);
      }
    }

    // Separate matches by strength
    final strongMatches = uniqueMatches
        .where((m) => m.result == MatchResult.strong)
        .toList();
    final weakMatches = uniqueMatches
        .where((m) => m.result == MatchResult.weak)
        .toList();

    // If no matches, show empty state
    if (uniqueMatches.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Possible Matches',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.text,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Matches Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When items match your report, they will appear here.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Possible Matches',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ SUMMARY HEADER ============
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${uniqueMatches.length} Match${uniqueMatches.length > 1 ? 'es' : ''} Found',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        Row(
                          children: [
                            if (strongMatches.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${strongMatches.length} Strong',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (weakMatches.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${weakMatches.length} Weak',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============ STRONG MATCHES ============
            if (strongMatches.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Strong Matches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${strongMatches.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...strongMatches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MatchCard(
                  match: match,
                  isStrong: true,
                  onChat: () => _openChat(context, match),
                  onViewDetails: () => _openDetails(context, match, true),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // ============ WEAK MATCHES ============
            if (weakMatches.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weak Matches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weakMatches.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...weakMatches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MatchCard(
                  match: match,
                  isStrong: false,
                  onChat: () => _openChat(context, match),
                  onViewDetails: () => _openDetails(context, match, false),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ============ MATCH CARD WIDGET ============
class _MatchCard extends StatelessWidget {
  final MatchDocument match;
  final bool isStrong;
  final VoidCallback onChat;
  final Future<void> Function() onViewDetails;

  const _MatchCard({
    required this.match,
    required this.isStrong,
    required this.onChat,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final matchColor = isStrong ? AppColors.secondary : AppColors.primary;
    final scorePercentage = ((match.score) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStrong
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
        ),
        boxShadow: isStrong
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: matchColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: matchColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isStrong ? Icons.check_circle : Icons.search,
                      color: matchColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isStrong ? 'Strong Match' : 'Weak Match',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: matchColor,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Match Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: matchColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$scorePercentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: matchColor,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Item Info
          Text(
            match.report.itemName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                match.report.category,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.report.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Image if available
          if (match.report.imageUrl != null &&
              match.report.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                match.report.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: AppColors.surface,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.muted,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons row
          Row(
            children: [
              // View Details button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: matchColor,
                    ),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: matchColor,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: matchColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Chat button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isStrong ? AppColors.secondary : AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}