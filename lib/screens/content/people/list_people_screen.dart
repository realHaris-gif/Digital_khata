import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/customer_service.dart';
import 'add_people_screen.dart';
import 'customer_detail_screen.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/customer_card.dart';

class ListPeopleScreen extends StatefulWidget {
  const ListPeopleScreen({Key? key}) : super(key: key);

  @override
  State<ListPeopleScreen> createState() => _ListPeopleScreenState();
}

class _ListPeopleScreenState extends State<ListPeopleScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<Map<String, dynamic>> _getCustomerStats(String customerId) async {
    try {
      // Use CustomerService timeline instead of querying non-existent tables directly
      final timeline = await CustomerService.getCustomerTimeline(customerId);

      final transactionCount = timeline.length;
      final lastTransaction = timeline.isNotEmpty
          ? DateTime.tryParse(timeline.first['date']?.toString() ?? '')
          : null;

      return {
        'transactionCount': transactionCount,
        'lastTransactionDate': lastTransaction,
      };
    } catch (e) {
      debugPrint('Error fetching customer stats: $e');
      return {
        'transactionCount': 0,
        'lastTransactionDate': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? spaceCadet : Colors.white,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notification_important_rounded,
                  color: isDark ? jordyBlue : oxfordBlue,
                ),
                tooltip: 'Payment Reminders',
                onPressed: () {
                  context.push('/customers/reminders');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Customers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : oxfordBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your customer ledger',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),

          // Search Bar (Sliver)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDark ? Colors.white : oxfordBlue,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search customers, phone...',
                  hintStyle: TextStyle(
                    color: isDark ? lavender.withOpacity(0.5) : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? jordyBlue : Colors.grey.shade500,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? jordyBlue : yinMnBlue,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Customer List or Empty State
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('customers')
                .stream(primaryKey: ['id'])
                .eq('user_id', userId)
                .order('name', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        isDark ? jordyBlue : yinMnBlue,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'Error',
                    subtitle: 'Failed to load customers: ${snapshot.error}',
                    icon: Icons.error_outline_rounded,
                  ),
                );
              }

              final customers = snapshot.data ?? [];

              final filtered = customers.where((c) {
                final name = (c['name'] ?? '').toString().toLowerCase();
                final phone = (c['phone'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    phone.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: _searchQuery.isEmpty
                        ? 'No customers yet'
                        : 'No customers found',
                    subtitle: _searchQuery.isEmpty
                        ? 'Create your first customer to get started'
                        : 'Try adjusting your search terms',
                    icon: Icons.person_search_rounded,
                    actionLabel: _searchQuery.isEmpty ? 'Add Customer' : null,
                    onAction: _searchQuery.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddPeopleScreen(),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final customerId = item['id'].toString();
                      final name = item['name'] ?? 'Unknown Customer';
                      final phone = item['phone'] ?? '';

                      return FutureBuilder<Map<String, double>>(
                        future: CustomerService.getCustomerTotals(customerId),
                        builder: (context, totalsSnapshot) {
                          // Skeleton shimmer loader while totals are loading
                          if (totalsSnapshot.connectionState == ConnectionState.waiting) {
                            return _buildCustomerCardSkeleton(isDark);
                          }

                          final totals =
                              totalsSnapshot.data ?? {'totalDue': 0.0};
                          final totalDue = totals['totalDue'] ?? 0.0;

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getCustomerStats(customerId),
                            builder: (context, statsSnapshot) {
                              final stats = statsSnapshot.data ?? {
                                'transactionCount': 0,
                                'lastTransactionDate': null,
                              };

                              return CustomerCard(
                                customerId: customerId,
                                name: name,
                                phone: phone,
                                totalDue: totalDue,
                                transactionCount:
                                    stats['transactionCount'] ?? 0,
                                lastTransactionDate:
                                    stats['lastTransactionDate'],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerDetailScreen(
                                        customerId: customerId,
                                        customerName: name,
                                        customerPhone: phone,
                                      ),
                                    ),
                                  );
                                },
                                onCallTap: phone.isNotEmpty
                                    ? () => _launchCall(phone)
                                    : null,
                                onWhatsAppTap: phone.isNotEmpty
                                    ? () => _launchWhatsApp(phone)
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1.0),
            curve: Curves.easeOutBack,
          ),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: isDark ? jordyBlue : oxfordBlue,
          foregroundColor: isDark ? oxfordBlue : Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPeopleScreen()),
            );
          },
          icon: const Icon(Icons.person_add_rounded),
          label: const Text(
            'Add Customer',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Skeleton Loader for Customer Cards matching the Blue Theme
  Widget _buildCustomerCardSkeleton(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.5) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.8) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? spaceCadet.withOpacity(0.4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? jordyBlue.withOpacity(0.1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 16,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}