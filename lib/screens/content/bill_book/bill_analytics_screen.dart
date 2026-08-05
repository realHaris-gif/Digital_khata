import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/theme/app_theme.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final billAnalyticsProvider =
    FutureProvider.family<List<Invoice>, String>((ref, userId) async {
  final repo = ref.watch(invoiceRepoProvider);
  return repo.getInvoices(userId: userId, limit: 1000);
});

class BillAnalyticsScreen extends ConsumerStatefulWidget {
  const BillAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BillAnalyticsScreen> createState() =>
      _BillAnalyticsScreenState();
}

class _BillAnalyticsScreenState extends ConsumerState<BillAnalyticsScreen> {
  int _selectedTab = 0; // 0: By Category, 1: All analytics
  int _selectedFilterIndex = 0;
  DateTime _currentSelectedDate = DateTime.now();
  bool _showPaymentBreakdown = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _filters = [
    'All Invoices',
    'Paid',
    'Partially Paid',
    'Pending',
    'Cancelled'
  ];

  void _refresh(String userId) {
    ref.invalidate(billAnalyticsProvider(userId));
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentSelectedDate = DateTime(
        _currentSelectedDate.year,
        _currentSelectedDate.month + increment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isDark = ThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          LanguageController.isUrdu ? 'بل کے تجزیات' : 'Bill Analytics',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => _refresh(userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(
              child: Text(
                l10n.error,
                textDirection: LanguageController.contentTextDirection,
              ),
            )
          : ref.watch(billAnalyticsProvider(userId)).when(
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return Center(
                      child: Text(
                        LanguageController.isUrdu ? 'تجزیات کے لیے کوئی انوائس ڈیٹا دستیاب نہیں ہے۔' : 'No invoice data available for analytics.',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // 1. Calculations derived from non-cancelled invoices
                  final nonCancelled = invoices
                      .where((i) => i.status != InvoiceStatus.cancelled)
                      .toList();

                  final double totalSalesVolume = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.total);

                  final double totalRevenueCollected = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.totalPaid);

                  final double avgInvoiceValue = nonCancelled.isNotEmpty
                      ? totalSalesVolume / nonCancelled.length
                      : 0.0;

                  final double totalOutstanding = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.remainingBalance);

                  // 2. Payment Method Breakdown
                  final Map<String, double> methodTotals = {};
                  for (var inv in nonCancelled) {
                    for (var pay in inv.payments) {
                      methodTotals[pay.paymentMethod] =
                          (methodTotals[pay.paymentMethod] ?? 0.0) + pay.amount;
                    }
                  }

                  // 3. Monthly Sales Chart Grouping (using inv.createdAt)
                  final Map<String, double> monthlySalesMap = {};
                  for (var inv in nonCancelled) {
                    final key =
                        _monthNames[inv.createdAt.month - 1].substring(0, 3);
                    monthlySalesMap[key] =
                        (monthlySalesMap[key] ?? 0.0) + inv.total;
                  }

                  final List<MapEntry<String, double>> chartDataList =
                      monthlySalesMap.entries.toList();

                  double maxSalesVal = 1.0;
                  for (var entry in chartDataList) {
                    if (entry.value > maxSalesVal) maxSalesVal = entry.value;
                  }

                  return RefreshIndicator(
                    color: yinMnBlue,
                    onRefresh: () async => _refresh(userId),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 90),
                      child: Column(
                        children: [
                          // --- 1. SEGMENTED TAB TOGGLE ---
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedTab = 0),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 0
                                            ? yinMnBlue
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        LanguageController.isUrdu ? 'زمرہ کے لحاظ سے' : 'By Category',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _selectedTab == 0
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.textTertiary
                                                  : AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedTab = 1),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 1
                                            ? yinMnBlue
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        LanguageController.isUrdu ? 'تمام تجزیات' : 'All analytics',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _selectedTab == 1
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.textTertiary
                                                  : AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // --- 2. MONTH SELECTOR BAR ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                                onPressed: () => _changeMonth(-1),
                              ),
                              Text(
                                '${_monthNames[_currentSelectedDate.month - 1]} ${_currentSelectedDate.year}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                                onPressed: () => _changeMonth(1),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // --- 3. FILTER CHIPS ROW ---
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                ...List.generate(_filters.length, (index) {
                                  final isSelected =
                                      _selectedFilterIndex == index;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedFilterIndex = index),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? yinMnBlue
                                            : (isDark
                                                ? AppColors.darkSurface
                                                : Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? yinMnBlue
                                              : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.borderLight),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _filters[index],
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white70
                                                      : AppColors.textPrimary),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.close_rounded,
                                                size: 14, color: Colors.white),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- 4. BAR CHART ---
                          if (chartDataList.isEmpty)
                            Container(
                              height: 120,
                              alignment: Alignment.center,
                              child: Text(
                                LanguageController.isUrdu ? 'ابھی تک کوئی چارٹ ڈیٹا درج نہیں کیا گیا' : 'No chart data recorded yet',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textTertiary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 190,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                    chartDataList.length.clamp(0, 6), (index) {
                                  final entry = chartDataList[index];
                                  final monthLabel = entry.key;
                                  final val = entry.value;
                                  final isActive =
                                      index == chartDataList.length - 1;
                                  final heightRatio =
                                      (val / maxSalesVal).clamp(0.12, 1.0);

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs.${val.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 28,
                                        height: 110 * heightRatio,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? yinMnBlue
                                              : (isDark
                                                  ? AppColors.darkSurface2
                                                  : Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        monthLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isActive
                                              ? (isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimary)
                                              : (isDark
                                                  ? AppColors.textTertiary
                                                  : AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),

                          const SizedBox(height: 28),

                          // --- 5. 3-COLUMN METRIC CARDS ---
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.calculate_outlined,
                                  value:
                                      'Rs. ${avgInvoiceValue.toStringAsFixed(0)}',
                                  label: LanguageController.isUrdu ? 'اوسط بل ویلیو' : 'Avg Bill Value',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.payments_outlined,
                                  value:
                                      'Rs. ${totalRevenueCollected.toStringAsFixed(0)}',
                                  label: LanguageController.isUrdu ? 'وصول شدہ' : 'Collected',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.warning_amber_rounded,
                                  value:
                                      'Rs. ${totalOutstanding.toStringAsFixed(0)}',
                                  label: LanguageController.isUrdu ? 'بقایا' : 'Outstanding',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // --- 6. UNPAID / OVERDUE INVOICES LIST ---
                          _buildOutstandingInvoicesSummary(
                              nonCancelled, isDark),

                          const SizedBox(height: 20),

                          // --- 7. EXPANDABLE PAYMENT METHOD BREAKDOWN ---
                          _buildListTileCard(
                            title: LanguageController.isUrdu ? 'ادائیگی کے طریقہ کار کی تفصیل' : 'Payment Method Breakdown',
                            isDark: isDark,
                            trailingIcon: _showPaymentBreakdown
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            onTap: () {
                              setState(() {
                                _showPaymentBreakdown = !_showPaymentBreakdown;
                              });
                            },
                          ),

                          if (_showPaymentBreakdown) ...[
                            const SizedBox(height: 12),
                            _buildPaymentMethodDetails(
                              methodTotals,
                              totalRevenueCollected,
                              isDark,
                            ),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: yinMnBlue)),
                error: (e, _) => Center(
                  child: Text(
                    '${l10n.error}: $e',
                    textDirection: LanguageController.contentTextDirection,
                  ),
                ),
              ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: yinMnBlue),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textTertiary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingInvoicesSummary(
      List<Invoice> invoices, bool isDark) {
    final unpaidInvoices = invoices
        .where((i) =>
            i.status == InvoiceStatus.pending ||
            i.status == InvoiceStatus.partiallyPaid ||
            i.status == InvoiceStatus.draft)
        .toList();

    if (unpaidInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LanguageController.isUrdu ? 'تمام بل مکمل طور پر ادا ہو چکے ہیں! بقایا بیلنس صفر ہے۔' : 'All bills are fully settled! Outstanding balance is zero.',
                textDirection: LanguageController.contentTextDirection,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LanguageController.isUrdu ? 'زیر التوا اور غیر ادا شدہ بل (${unpaidInvoices.length})' : 'Pending & Unpaid Bills (${unpaidInvoices.length})',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...unpaidInvoices.take(5).map((inv) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        inv.customerName ?? (LanguageController.isUrdu ? 'نامعلوم گاہک' : 'Unassigned Customer'),
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${inv.remainingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDetails(
      Map<String, double> methodTotals, double totalCollected, bool isDark) {
    if (methodTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          LanguageController.isUrdu ? 'ادائیگی کی کوئی تفصیل درج نہیں کی گئی۔' : 'No payment breakdowns recorded yet.',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            color: isDark ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: methodTotals.entries.map((entry) {
          final double percentage = totalCollected > 0
              ? (entry.value / totalCollected).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Rs. ${entry.value.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: yinMnBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor:
                      isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                  color: yinMnBlue,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListTileCard({
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    IconData trailingIcon = Icons.chevron_right_rounded,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          trailingIcon,
          color: isDark ? AppColors.textTertiary : AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
