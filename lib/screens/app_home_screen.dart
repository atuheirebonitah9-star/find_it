import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'report_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'chat/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
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

  // Get counts for filter tabs
  Future<Map<String, int>> _getFilterCounts() async {
    final allSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .get();
    final lostSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'lost')
        .get();
    final foundSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'found')
        .get();

    return {
      'All': allSnapshot.docs.length,
      'Lost': lostSnapshot.docs.length,
      'Found': foundSnapshot.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildLocationContext(),
          FutureBuilder<Map<String, int>>(
            future: _getFilterCounts(),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {'All': 0, 'Lost': 0, 'Found': 0};
              return _buildFilterTabs(counts);
            },
          ),
          Expanded(child: _buildItemList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ============ APP BAR ============
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.search, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'FindIt',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'Chats',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.person_outline,
          tooltip: 'Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.logout,
          tooltip: 'Sign out',
          onTap: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: AppColors.text, size: 22),
          ),
        ),
      ),
    );
  }

  // ============ SEARCH SECTION ============
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search for an item...',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.mic, color: AppColors.primary),
                      splashRadius: 20,
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.qr_code_scanner_outlined,
                        color: AppColors.muted,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickFilterChip(Icons.location_on_outlined, 'Near Me'),
              const SizedBox(width: 8),
              _buildQuickFilterChip(Icons.tune_outlined, 'Filter'),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    'Found $count items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  // ============ LOCATION CONTEXT ============
  Widget _buildLocationContext() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '📍 Near You · Showing items within 5km radius',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Refresh location
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ============ FILTER TABS ============
  Widget _buildFilterTabs(Map<String, int> counts) {
    final tabs = ['All', 'Lost', 'Found'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = _statusFilter == tab;
          final count = counts[tab] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? AppColors.text : AppColors.muted,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============ ITEM LIST ============
  Widget _buildItemList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _itemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final name = (doc.data()['itemName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.muted,
                ),
                SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data();
            final itemId = filteredDocs[index].id;
            final status = (data['status'] ?? 'found').toString().toLowerCase();
            final isLost = status == 'lost';

            // Staggered animation
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _ModernItemCard(
                data: data,
                isLost: isLost,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ItemDetailsScreen(itemId: itemId, data: data),
                    ),
                  );
                },
                onActionTap: () {
                  // Handle report/claim action
                  _showActionDialog(context, data, isLost);
                },
              ),
            );
          },
        );
      },
    );
  }

  // ============ FLOATING ACTION BUTTON ============
  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabController,
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportItemScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Report Lost Item',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  // ============ HELPER METHODS ============
  void _showActionDialog(
    BuildContext context,
    Map<String, dynamic> data,
    bool isLost,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isLost ? 'Report this lost item?' : 'Claim this found item?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['itemName'] ?? 'Unnamed item',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle the action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isLost
                                  ? 'Reported lost item: ${data['itemName']}'
                                  : 'Claimed found item: ${data['itemName']}',
                            ),
                            backgroundColor: isLost
                                ? AppColors.lostColor
                                : AppColors.secondary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLost
                            ? AppColors.lostColor
                            : AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isLost ? 'Report' : 'Claim'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ============ MODERN ITEM CARD ============
class _ModernItemCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isLost;
  final VoidCallback onTap;
  final VoidCallback onActionTap;

  const _ModernItemCard({
    required this.data,
    required this.isLost,
    required this.onTap,
    required this.onActionTap,
  });

  @override
  State<_ModernItemCard> createState() => _ModernItemCardState();
}

class _ModernItemCardState extends State<_ModernItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isLost = widget.isLost;
    final hasImage =
        data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
    final timeAgo = data['createdAt'] != null
        ? _getTimeAgo((data['createdAt'] as Timestamp).toDate())
        : 'Recently';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        transform: Matrix4.identity()
          ..scaleByDouble(
            _hovered ? 1.01 : 1.0,
            _hovered ? 1.01 : 1.0,
            1.0,
            1.0,
          ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image/Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLost
                            ? [
                                AppColors.lostColor.withValues(alpha: 0.1),
                                AppColors.lostColor.withValues(alpha: 0.05),
                              ]
                            : [
                                AppColors.secondary.withValues(alpha: 0.1),
                                AppColors.secondary.withValues(alpha: 0.05),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildItemIcon(isLost);
                              },
                            ),
                          )
                        : _buildItemIcon(isLost),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['itemName'] ?? 'Unnamed item',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${data['location'] ?? 'Unknown location'} · ${_getDistance()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status & Action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLost
                              ? AppColors.lostColor.withValues(alpha: 0.1)
                              : AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLost ? 'LOST' : 'FOUND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isLost
                                ? AppColors.lostColor
                                : AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: widget.onActionTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isLost ? 'Report' : 'Claim',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
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

  Widget _buildItemIcon(bool isLost) {
    final itemName = widget.data['itemName']?.toLowerCase() ?? '';
    IconData icon;

    if (itemName.contains('wallet')) {
      icon = Icons.wallet;
    } else if (itemName.contains('backpack') || itemName.contains('bag')) {
      icon = Icons.backpack;
    } else if (itemName.contains('phone')) {
      icon = Icons.phone_android;
    } else if (itemName.contains('key')) {
      icon = Icons.vpn_key;
    } else if (itemName.contains('laptop') || itemName.contains('computer')) {
      icon = Icons.laptop;
    } else if (itemName.contains('glasses')) {
      icon = Icons.visibility;
    } else {
      icon = isLost ? Icons.search : Icons.check_circle_outline;
    }

    return Icon(
      icon,
      color: isLost ? AppColors.lostColor : AppColors.secondary,
      size: 30,
    );
  }

  String _getDistance() {
    // Mock distance - replace with actual location logic
    final distances = [
      '200m away',
      '500m away',
      '1.2km away',
      '2km away',
      '3.5km away',
    ];
    return distances[DateTime.now().millisecondsSinceEpoch % distances.length];
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
    if (difference.inDays > 0) return '${difference.inDays} days ago';
    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
    return 'Just now';
  }
}
