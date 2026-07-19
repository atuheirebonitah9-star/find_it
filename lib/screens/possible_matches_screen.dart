import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../matching_logic.dart';
import '../providers/chat_provider.dart';
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
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A4A),
        title: const Text('Possible Matches'),
      ),
      body: matches.isEmpty
          ? const Center(child: Text('No matches found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return _buildMatchCard(context, match);
              },
            ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchDocument match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.report.itemName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2A4A),
              ),
            ),
            const SizedBox(height: 4),
            Text('Category: ${match.report.category}'),
            Text('Location: ${match.report.location}'),
            Text(
              'Date: ${match.report.date.month}/${match.report.date.day}/${match.report.date.year}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openChat(context, match),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Chat about this item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
