import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
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
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.3) : AppColors.lavender,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionCard(
                icon: Icons.note_add_outlined,
                iconColor: AppColors.jordyBlue,
                title: LanguageController.isUrdu ? 'نئی انوائس بنائیں' : 'Create new invoice',
                subtitle:
                    LanguageController.isUrdu ? 'آسانی سے انوائس بنانے اور اسے اپنے کھاتے میں محفوظ کرنے کے لیے تمام مطلوبہ تفصیلات شامل کریں۔' : 'Add all required details to easily create an invoice and save it to your ledger.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildOptionCard(
                icon: Icons.post_add_rounded,
                iconColor: Colors.greenAccent,
                title: LanguageController.isUrdu ? 'موجودہ انوائس شامل کریں' : 'Add an existing invoice',
                subtitle:
                    LanguageController.isUrdu ? 'اپنے ڈیٹا بیس میں موجودہ ٹرانزیکشن یا مسودہ انوائس درج کریں۔' : 'Record an existing transaction or draft invoice into your database.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lavender.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    Text(
                      title,
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.7),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = ThemeController.isDarkMode;
    final invoicesAsync = ref.watch(allInvoicesProvider);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Text(
            LanguageController.isUrdu ? 'انوائسز' : 'Invoices',
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
                  color: AppColors.yinMnBlue,
                  onRefresh: () async => ref.invalidate(allInvoicesProvider),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.sm,
                      bottom: bottomSafeArea + 140,
                    ),
                    child: Column(
                      children: [
                        // Segmented Toggle Tab
                        Container(
                          height: 46,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lavender.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : Colors.transparent,
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
                                          ? (isDark ? AppColors.darkBackground : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      LanguageController.isUrdu ? 'ارسال کردہ' : 'Sent',
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                        fontWeight: _selectedTab == 0
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: _selectedTab == 0
                                            ? (isDark ? Colors.white : AppColors.oxfordBlue)
                                            : (isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6)),
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
                                          ? (isDark ? AppColors.darkBackground : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      LanguageController.isUrdu ? 'وصول شدہ' : 'Incoming',
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                        fontWeight: _selectedTab == 1
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: _selectedTab == 1
                                            ? (isDark ? Colors.white : AppColors.oxfordBlue)
                                            : (isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Search Input Field
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                          decoration: InputDecoration(
                            hintText: LanguageController.isUrdu ? 'انوائس نمبر یا گاہک کے ذریعے تلاش کریں' : 'Search by invoice # or customer',
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.lavender.withValues(alpha: 0.5) : AppColors.spaceCadet.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                            ),
                            fillColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Filter Chips Row
                        Row(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            _buildFilterChip(
                              label: LanguageController.isUrdu ? 'تمام تاریخیں' : 'All dates',
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(
                              label: _selectedStatusFilter == 'All status' 
                                  ? (LanguageController.isUrdu ? 'تمام حالتیں' : 'All status') 
                                  : (_selectedStatusFilter == 'unpaid' 
                                      ? (LanguageController.isUrdu ? 'غیر ادا شدہ / التوا' : 'Unpaid / Pending') 
                                      : (LanguageController.isUrdu ? 'ادا شدہ' : 'Paid')),
                              icon: Icons.tune_rounded,
                              isDark: isDark,
                              onTap: () {
                                _showStatusFilterMenu(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (filteredInvoices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              LanguageController.isUrdu ? 'کوئی انوائس نہیں ملی' : 'No invoices found',
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
              error: (err, stack) => Center(
                child: Text(
                  LanguageController.isUrdu ? 'انوائسز لوڈ کرنے میں ناکام: $err' : 'Failed to load invoices: $err',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                ),
              ),
            ),

            // Floating Action Button with safe bottom padding clearance
            Positioned(
              bottom: bottomSafeArea + 16,
              right: 16,
              child: const CreateInvoiceFAB(),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterMenu(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                LanguageController.isUrdu ? 'تمام حالتیں' : 'All status',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
              ),
              onTap: () {
                setState(() => _selectedStatusFilter = 'All status');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(
                LanguageController.isUrdu ? 'غیر ادا شدہ / التوا' : 'Unpaid / Pending',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
              ),
              onTap: () {
                setState(() => _selectedStatusFilter = 'unpaid');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(
                LanguageController.isUrdu ? 'ادا شدہ' : 'Paid',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
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
          color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
          ),
        ),
        child: Row(
          textDirection: LanguageController.contentTextDirection,
          children: [
            Icon(icon, size: 14, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
            const SizedBox(width: 6),
            Text(
              label,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.lavender : AppColors.oxfordBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
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
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Row(
              textDirection: LanguageController.contentTextDirection,
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
                    textDirection: LanguageController.contentTextDirection,
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
                        LanguageController.isUrdu ? 'اجراء: $issueDateStr' : 'Issued: $issueDateStr',
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
              ),
            ),
            _buildRowDetail(LanguageController.isUrdu ? 'آخری تاریخ' : 'Due date', dueDateStr, isDark: isDark),
            const SizedBox(height: AppSpacing.xs),
            _buildRowDetail(
              LanguageController.isUrdu ? 'انوائس کی رقم' : 'Invoice amount',
              'Rs. ${item.total.toStringAsFixed(2)}',
              isDark: isDark,
              isBoldValue: true,
              isCurrency: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRowDetail(
              LanguageController.isUrdu ? 'وصول کنندہ' : 'Recipient',
              item.customerName ?? (LanguageController.isUrdu ? 'واک ان کسٹمر' : 'Walk-in Customer'),
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
    bool isCurrency = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: LanguageController.contentTextDirection,
      children: [
        Text(
          label,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.oxfordBlue,
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}