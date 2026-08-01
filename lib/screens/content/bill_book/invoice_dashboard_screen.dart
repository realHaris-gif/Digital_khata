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

const emerald = Color(0xFF059669);

final dashboardInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repo = ref.watch(invoiceRepoProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return [];
  return repo.getInvoices(userId: userId);
});

class InvoiceDashboardScreen extends ConsumerStatefulWidget {
  const InvoiceDashboardScreen({super.key});

  @override
  ConsumerState<InvoiceDashboardScreen> createState() =>
      _InvoiceDashboardScreenState();
}

class _InvoiceDashboardScreenState
    extends ConsumerState<InvoiceDashboardScreen> {
  void _refresh() {
    ref.invalidate(dashboardInvoicesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final invoicesAsync = ref.watch(dashboardInvoicesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Bill Book',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          invoicesAsync.when(
            data: (invoices) {
              // Financial Metrics
              final totalSales =
                  invoices.fold(0.0, (sum, inv) => sum + inv.total);
              final totalCollected =
                  invoices.fold(0.0, (sum, inv) => sum + inv.totalPaid);
              final totalPending =
                  invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

              final recentInvoices = invoices.take(5).toList();

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Metric Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMetricCard(
                            context: context,
                            title: 'Total Sales',
                            amount: 'Rs. ${totalSales.toStringAsFixed(2)}',
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                          _buildMetricCard(
                            context: context,
                            title: 'Collected',
                            amount: 'Rs. ${totalCollected.toStringAsFixed(2)}',
                            icon: Icons.verified_rounded,
                            color: emerald,
                            isDark: isDark,
                          ),
                          _buildMetricCard(
                            context: context,
                            title: 'Pending Dues',
                            amount: 'Rs. ${totalPending.toStringAsFixed(2)}',
                            icon: Icons.pending_actions_rounded,
                            color: Colors.amber.shade700,
                            isDark: isDark,
                          ),
                          _buildMetricCard(
                            context: context,
                            title: 'Invoices Count',
                            amount: '${invoices.length}',
                            icon: Icons.description_outlined,
                            color: Colors.purple,
                            isDark: isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick Action Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.add_circle_outline_rounded,
                              label: 'New Invoice',
                              isDark: isDark,
                              onTap: () async {
                                final res = await context.push('/bill-book/create');
                                if (res == true) _refresh();
                              },
                            ),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.list_alt_rounded,
                              label: 'All Invoices',
                              isDark: isDark,
                              onTap: () => context.push('/bill-book/invoices'),
                            ),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.analytics_outlined,
                              label: 'Analytics',
                              isDark: isDark,
                              onTap: () => context.push('/bill-book/analytics'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Activity Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Invoices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/bill-book/invoices'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (recentInvoices.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            'No invoices created yet.',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentInvoices.length,
                          itemBuilder: (context, index) {
                            return _buildDashboardInvoiceCard(
                              context,
                              recentInvoices[index],
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
                'Failed to load dashboard: $err',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ),

          // Reusable Persistent Create Invoice Floating Button
          const CreateInvoiceFAB(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardInvoiceCard(
    BuildContext context,
    Invoice item,
    bool isDark,
  ) {
    final issueDateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);

    return GestureDetector(
      onTap: () => context.push('/bill-book/invoice/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Row(
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
                    '${item.customerName ?? "Walk-in Customer"} • $issueDateStr',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${item.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                InvoiceStatusBadge(status: item.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}