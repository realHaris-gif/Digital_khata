import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/bill_book/create_invoice_fab.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

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

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            LanguageController.isUrdu ? 'بل بک' : 'Bill Book',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.oxfordBlue,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
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
                  color: AppColors.yinMnBlue,
                  onRefresh: () async => _refresh(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.sm,
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
                              title: LanguageController.isUrdu ? 'کل فروخت' : 'Total Sales',
                              amount: 'Rs. ${totalSales.toStringAsFixed(2)}',
                              icon: Icons.receipt_long_rounded,
                              color: AppColors.jordyBlue,
                              isDark: isDark,
                            ),
                            _buildMetricCard(
                              context: context,
                              title: LanguageController.isUrdu ? 'وصول شدہ' : 'Collected',
                              amount: 'Rs. ${totalCollected.toStringAsFixed(2)}',
                              icon: Icons.verified_rounded,
                              color: Colors.green.shade400,
                              isDark: isDark,
                            ),
                            _buildMetricCard(
                              context: context,
                              title: LanguageController.isUrdu ? 'بقایا واجبات' : 'Pending Dues',
                              amount: 'Rs. ${totalPending.toStringAsFixed(2)}',
                              icon: Icons.pending_actions_rounded,
                              color: AppColors.warning,
                              isDark: isDark,
                            ),
                            _buildMetricCard(
                              context: context,
                              title: LanguageController.isUrdu ? 'انوائسز کی تعداد' : 'Invoices Count',
                              amount: '${invoices.length}',
                              icon: Icons.description_outlined,
                              color: AppColors.lavender,
                              isDark: isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Quick Action Bar
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.add_circle_outline_rounded,
                                label: LanguageController.isUrdu ? 'نئی انوائس' : 'New Invoice',
                                isDark: isDark,
                                onTap: () async {
                                  final res = await context.push('/bill-book/create');
                                  if (res == true) _refresh();
                                },
                              ),
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.list_alt_rounded,
                                label: LanguageController.isUrdu ? 'تمام انوائسز' : 'All Invoices',
                                isDark: isDark,
                                onTap: () => context.push('/bill-book/invoices'),
                              ),
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.analytics_outlined,
                                label: LanguageController.isUrdu ? 'تجزیات' : 'Analytics',
                                isDark: isDark,
                                onTap: () => context.push('/bill-book/analytics'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Recent Activity Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              LanguageController.isUrdu ? 'حالیہ انوائسز' : 'Recent Invoices',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/bill-book/invoices'),
                              child: Text(
                                LanguageController.isUrdu ? 'سب دیکھیں' : 'View All',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (recentInvoices.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Text(
                              LanguageController.isUrdu ? 'ابھی تک کوئی انوائس نہیں بنائی گئی۔' : 'No invoices created yet.',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6),
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
              error: (err, stack) => Center(
                child: Text(
                  LanguageController.isUrdu ? 'ڈیش بورڈ لوڈ کرنے میں ناکام: $err' : 'Failed to load dashboard: $err',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                ),
              ),
            ),

            // Reusable Persistent Create Invoice Floating Button
            const CreateInvoiceFAB(),
          ],
        ),
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
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
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
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.lavender : AppColors.spaceCadet.withValues(alpha: 0.7),
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
                color: isDark ? Colors.white : AppColors.oxfordBlue,
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue, size: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.lavender : AppColors.spaceCadet,
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
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lavender.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 20,
                color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.invoiceNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                    ),
                  ),
                  Text(
                    '${item.customerName ?? (LanguageController.isUrdu ? 'واک ان کسٹمر' : 'Walk-in Customer')} • $issueDateStr',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
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
                    color: isDark ? Colors.white : AppColors.oxfordBlue,
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