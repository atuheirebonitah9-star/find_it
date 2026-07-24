import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class MyLostItemsScreen extends StatelessWidget {
  const MyLostItemsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _myLostItemsStream(
      String uid) {
    return FirebaseFirestore.instance
        .collection('lost_reports')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Not logged in.',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Lost Items',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _myLostItemsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Inter',
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
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
                    'No lost items reported yet.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you report a lost item, it will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate items with images from those without
          final withImages = docs.where((d) {
            final imageUrl = d.data()['imageUrl'];
            return imageUrl != null &&
                imageUrl.toString().trim().isNotEmpty;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image gallery section ──────────────────────────────
                if (withImages.isNotEmpty) ...[
                  const Text(
                    'Item Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: withImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final data = withImages[index].data();
                      return _ImageCard(data: data);
                    },
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Full list section ──────────────────────────────────
                const Text(
                  'All Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return _ReportListTile(data: data);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Image card widget ────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ImageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final imageUrl = (data['imageUrl'] ?? '').toString().trim();
        if (imageUrl.isNotEmpty) {
          _showFullImage(context, imageUrl);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceContainerHighest.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  data['imageUrl'] as String,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, _, __) => Container(
                    color: AppColors.surface,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.muted,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['itemName'] ?? 'Unnamed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.text,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['location'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Report list tile widget ──────────────────────────────────────────────────

class _ReportListTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportListTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasImage = data['imageUrl'] != null &&
        data['imageUrl'].toString().trim().isNotEmpty;

    final isResolved = data['status']?.toString().toLowerCase() == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: hasImage
              ? Image.network(
                  data['imageUrl'] as String,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          data['itemName'] ?? 'Unnamed item',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.text,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['location'] ?? 'Unknown location',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(data['date']),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isResolved
                ? AppColors.secondary.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isResolved
                  ? AppColors.secondary.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            (data['status'] ?? 'open').toString().toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isResolved ? AppColors.secondary : AppColors.primary,
              fontFamily: 'Plus Jakarta Sans',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.muted,
        size: 24,
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final date = (value as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}