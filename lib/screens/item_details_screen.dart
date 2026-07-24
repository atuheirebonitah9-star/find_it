import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = data['status']?.toString().toLowerCase() == 'lost';
    final statusColor = isLost ? AppColors.primary : AppColors.secondary;
    final statusBgColor = isLost 
        ? AppColors.primary.withOpacity(0.15) 
        : AppColors.secondary.withOpacity(0.15);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          data['itemName'] ?? 'Item Details',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============ IMAGE ============
              _buildImageSection(),
              
              // ============ DETAILS ============
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLost ? Icons.search : Icons.check_circle,
                                color: statusColor,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLost ? 'LOST' : 'FOUND',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Date
                        if (data['createdAt'] != null)
                          Text(
                            _formatDate(data['createdAt']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontFamily: 'Inter',
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Item Name
                    Text(
                      data['itemName'] ?? 'Unnamed Item',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['location'] ?? 'Unknown location',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    
                    // Category
                    if (data['category'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data['category'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // ============ DESCRIPTION ============
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.surfaceContainerHighest.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        data['description'] ?? 'No description available',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                          height: 1.6,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ============ CONTACT INFORMATION ============
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.contact_mail_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['contact'] ?? 'No contact info',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.text,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // ============ CONTACT BUTTON ============
                    _buildContactButton(context, isLost),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ IMAGE SECTION ============
  Widget _buildImageSection() {
    final hasImage = data['imageUrl'] != null &&
        data['imageUrl'].toString().trim().isNotEmpty;

    if (hasImage) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          child: Image.network(
            data['imageUrl'],
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          ),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ============ CONTACT BUTTON ============
  Widget _buildContactButton(BuildContext context, bool isLost) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final currentUser = FirebaseAuth.instance.currentUser;
          final reporterUid = data['userId'];

          if (currentUser != null && reporterUid != null) {
            final String finderUid;
            final String ownerUid;

            if (isLost) {
              finderUid = currentUser.uid;
              ownerUid = reporterUid;
            } else {
              finderUid = reporterUid;
              ownerUid = currentUser.uid;
            }

            try {
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
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
                  SnackBar(
                    content: Text('Failed to open chat: $e'),
                    backgroundColor: AppColors.errorContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not contact reporter'),
                  backgroundColor: AppColors.errorContainer,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        },
        icon: Icon(
          Icons.message_outlined,
          color: Colors.black,
          size: 22,
        ),
        label: Text(
          isLost ? 'Contact Finder' : 'Contact Owner',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ============ HELPER METHODS ============
  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp is DateTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      } else if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
