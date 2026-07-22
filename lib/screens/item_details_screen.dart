import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/chat_provider.dart';
import 'chat/chat_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  static const Color primaryColor = Color(0xFF131B2E);
  static const Color secondaryColor = Color(0xFF006A61);
  static const Color backgroundColor = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF45464D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(data['itemName'] ?? 'Item Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor.withOpacity(0.8),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             if (data['imageUrl'] != null &&
    data['imageUrl'].toString().trim().isNotEmpty)
  Container(
    height: 250,
    child: Image.network(
      data['imageUrl'],
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 250,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        );
      },
    ),
  )
else
  Container(
    height: 200,
    color: Colors.grey[200],
    child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
  ), 
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: data['status'] == 'lost' ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['status']?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data['status'] == 'lost' ? Colors.red[800] : Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['itemName'] ?? 'Unnamed Item',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          data['location'] ?? 'Unknown location',
                          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['description'] ?? 'No description available',
                        style: const TextStyle(fontSize: 16, color: onSurface),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.contact_mail_outlined, color: secondaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['contact'] ?? 'No contact info',
                              style: const TextStyle(fontSize: 16, color: onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          final reporterUid = data['userId'];

                          if (currentUser != null && reporterUid != null) {
                            // Determine who is finder and owner (based on item status)
                            final isLost = data['status'] == 'lost';
                            final String finderUid;
                            final String ownerUid;

                            if (isLost) {
                              // Current user is finder if they're viewing a lost item and want to contact owner
                              finderUid = currentUser.uid;
                              ownerUid = reporterUid;
                            } else {
                              // Current user is owner if viewing a found item and want to contact finder
                              finderUid = reporterUid;
                              ownerUid = currentUser.uid;
                            }

                            try {
                              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                              final chatId = await chatProvider.createChat(
                                finderUid: finderUid,
                                ownerUid: ownerUid,
                                itemName: data['itemName'] ?? 'Item',
                              );

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chatId,
                                      otherUserUid: reporterUid,
                                      itemName: data['itemName'] ?? 'Item',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to open chat: $e')),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not contact reporter')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Contact Reporter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
