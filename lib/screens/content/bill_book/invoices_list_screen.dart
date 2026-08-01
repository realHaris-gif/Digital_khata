import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/widgets/bill_book/create_invoice_fab.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final allInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repo = ref.watch(invoiceRepoProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return [];
  return repo.getInvoices(userId: userId);
});

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  int _selectedTab = 0; // 0: Sent, 1: Incoming
  String _searchQuery = '';
  String _selectedStatusFilter = 'All status';

  void _showCreateInvoiceBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionCard(
                icon: Icons.note_add_outlined,
                iconColor: Colors.amber,
                title: 'Create new invoice',
                subtitle:
                    'Add all required details to easily create an invoice and save it to your ledger.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.post_add_rounded,
                iconColor: Colors.lightGreenAccent,
                title: 'Add an existing invoice',
                subtitle:
                    'Record an existing transaction or draft invoice into your database.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                        height: 1.3,
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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final invoicesAsync = ref.watch(allInvoicesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Invoices',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () => ref.invalidate(allInvoicesProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          invoicesAsync.when(
            data: (invoices) {
              final filteredInvoices = invoices.where((inv) {
                final matchesSearch = inv.invoiceNumber
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (inv.customerName ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());

                if (_selectedStatusFilter == 'All status') {
                  return matchesSearch;
                }
                return matchesSearch &&
                    inv.status.name.toLowerCase() ==
                        _selectedStatusFilter.toLowerCase();
              }).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allInvoicesProvider),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 120,
                  ),
                  child: Column(
                    children: [
                      // Segmented Toggle Tab
                      Container(
                        height: 46,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEF0F4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0
                                        ? (isDark ? const Color(0xFF2B2B2B) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sent',
                                    style: TextStyle(
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _selectedTab == 0
                                          ? (isDark ? Colors.white : Colors.black)
                                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1
                                        ? (isDark ? const Color(0xFF2B2B2B) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Incoming',
                                    style: TextStyle(
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _selectedTab == 1
                                          ? (isDark ? Colors.white : Colors.black)
                                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search Input Field
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search by invoice # or customer',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
                          ),
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: isDark
                                ? const BorderSide(color: Colors.white12)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips Row
                      Row(
                        children: [
                          _buildFilterChip(
                            label: 'All dates',
                            icon: Icons.calendar_today_outlined,
                            isDark: isDark,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: _selectedStatusFilter,
                            icon: Icons.tune_rounded,
                            isDark: isDark,
                            onTap: () {
                              _showStatusFilterMenu(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (filteredInvoices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No invoices found',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredInvoices.length,
                          itemBuilder: (context, index) {
                            return _buildDynamicInvoiceCard(
                              context,
                              filteredInvoices[index],
                              isDark,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load invoices: $err',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ),

          // Floating Action Button
          const CreateInvoiceFAB(),
        ],
      ),
    );
  }

  void _showStatusFilterMenu(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'All status',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                setState(() => _selectedStatusFilter = 'All status');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(
                'Unpaid / Pending',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                setState(() => _selectedStatusFilter = 'unpaid');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(
                'Paid',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                setState(() => _selectedStatusFilter = 'paid');
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicInvoiceCard(
    BuildContext context,
    Invoice item,
    bool isDark,
  ) {
    final issueDateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);
    final dueDateStr = DateFormat('MMM dd, yyyy').format(
      item.createdAt.add(const Duration(days: 14)),
    );

    return GestureDetector(
      onTap: () => context.push('/bill-book/invoice/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.invoiceNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Issued: $issueDateStr',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                InvoiceStatusBadge(status: item.status),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            _buildRowDetail('Due date', dueDateStr, isDark: isDark),
            const SizedBox(height: 6),
            _buildRowDetail(
              'Invoice amount',
              'Rs. ${item.total.toStringAsFixed(2)}',
              isDark: isDark,
              isBoldValue: true,
            ),
            const SizedBox(height: 6),
            _buildRowDetail(
              'Recipient',
              item.customerName ?? 'Walk-in Customer',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(
    String label,
    String value, {
    required bool isDark,
    bool isBoldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}