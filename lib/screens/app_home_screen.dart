import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'report_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'chat/chat_list_screen.dart';
import 'my_lost_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _itemsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    if (_statusFilter != 'All') {
      query = query.where('status', isEqualTo: _statusFilter.toLowerCase());
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Find It'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          _appAction(
            icon: Icons.image_search_outlined,
            tooltip: 'My Lost Items',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyLostItemsScreen()),
              );
            },
          ),
          _appAction(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chats',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          _appAction(
            icon: Icons.person_outline,
            tooltip: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _appAction(
            icon: Icons.logout,
            tooltip: 'Sign out',
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B4BFF), Color(0xFF7B61FF), Color(0xFF22C9A8)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Welcome back',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find what was lost near you',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Search for an item...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(
                          () => _searchQuery = value.trim().toLowerCase(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 46,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: ['All', 'Lost', 'Found'].map((status) {
                            final selected = _statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.13,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                                label: Text(status),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = status),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child:
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _itemsStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];
                                final filteredDocs = docs.where((doc) {
                                  if (_searchQuery.isEmpty) return true;
                                  final name = (doc.data()['itemName'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return name.contains(_searchQuery);
                                }).toList();

                                if (filteredDocs.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 48,
                                          color: AppColors.muted,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'No items found.',
                                          style: TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.only(top: 4),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (context, index) {
                                    final data = filteredDocs[index].data();
                                    final itemId = filteredDocs[index].id;
                                    final status = (data['status'] ?? 'found')
                                        .toString()
                                        .toLowerCase();
                                    final isLost = status == 'lost';

                                    return _HoverableItemCard(
                                      data: data,
                                      isLost: isLost,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ItemDetailsScreen(
                                              itemId: itemId,
                                              data: data,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportItemScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add),
        label: const Text('Report Item'),
      ),
    );
  }

  Widget _appAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: IconButton(
            tooltip: tooltip,
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}

class _HoverableItemCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isLost;
  final VoidCallback onTap;

  const _HoverableItemCard({
    required this.data,
    required this.isLost,
    required this.onTap,
  });

  @override
  State<_HoverableItemCard> createState() => _HoverableItemCardState();
}

class _HoverableItemCardState extends State<_HoverableItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isLost = widget.isLost;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()..scale(_hovered ? 1.01 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isLost
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.secondary.withValues(alpha: 0.2),
                  backgroundImage: data['imageUrl'] != null
                      ? NetworkImage(data['imageUrl'])
                      : null,
                  child: data['imageUrl'] == null
                      ? Icon(
                          isLost ? Icons.search : Icons.check_circle_outline,
                          color: isLost
                              ? AppColors.accent
                              : AppColors.secondary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['itemName'] ?? 'Unnamed item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(data['location'] ?? 'Unknown location').toString()} • ${data['status'] ?? 'found'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLost
                        ? AppColors.accent.withValues(alpha: 0.16)
                        : AppColors.secondary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isLost ? 'Lost' : 'Found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isLost ? AppColors.accent : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
