import 'package:flutter/material.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/services/analytics_service.dart';
import 'package:digital_khata/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsService _analyticsService;

  int _selectedTab = 0; // 0: By Category, 1: All analytics
  int _selectedFilterIndex = 0; // Filter index for chips
  DateTime _currentSelectedDate = DateTime.now();
  bool _showTopCustomers = false;

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
    'All',
    'Clear',
    'Partial',
    'High Due',
    'Overdue'
  ];

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
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
    final isDark = ThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? oxfordBlue : lavender.withValues(alpha: 0.3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? jordyBlue : oxfordBlue,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          LanguageController.isUrdu ? 'تجزیات' : 'Analytics',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            color: isDark ? Colors.white : oxfordBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
        child: Column(
          children: [
            // --- 1. SEGMENTED TAB TOGGLE ("By Category" / "All analytics") ---
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? spaceCadet : lavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? jordyBlue.withValues(alpha: 0.2) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? yinMnBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
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
                                    ? lavender.withValues(alpha: 0.7)
                                    : spaceCadet.withValues(alpha: 0.7)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? yinMnBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
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
                                    ? lavender.withValues(alpha: 0.7)
                                    : spaceCadet.withValues(alpha: 0.7)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. WORKING MONTH SELECTOR BAR ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark ? jordyBlue : spaceCadet,
                  ),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthNames[_currentSelectedDate.month - 1]} ${_currentSelectedDate.year}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? jordyBlue : spaceCadet,
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
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? spaceCadet : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
                      ),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: isDark ? jordyBlue : yinMnBlue,
                    ),
                  ),
                  ...List.generate(_filters.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    final filterLabel = _filters[index];
                    final translatedFilterLabel = LanguageController.isUrdu
                        ? (filterLabel == 'All' ? 'سب' : filterLabel == 'Clear' ? 'صاف' : filterLabel == 'Partial' ? 'جزوی' : filterLabel == 'High Due' ? 'زیادہ بقایا' : 'اوورڈیو')
                        : filterLabel;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? yinMnBlue
                              : (isDark
                                  ? spaceCadet.withValues(alpha: 0.6)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? yinMnBlue
                                : (isDark
                                    ? jordyBlue.withValues(alpha: 0.2)
                                    : lavender),
                          ),
                        ),
                        child: Row(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Text(
                              translatedFilterLabel,
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? lavender
                                        : oxfordBlue),
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

            // --- 4. REAL MONTHLY SUMMARY BAR CHART ---
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getMonthlySummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator(color: yinMnBlue)),
                  );
                }

                final monthlyData = snapshot.data ?? [];
                if (monthlyData.isEmpty) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      LanguageController.isUrdu ? 'کوئی لین دین کی ہسٹری دستیاب نہیں ہے' : 'No transaction history available',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        color: isDark ? lavender.withValues(alpha: 0.6) : spaceCadet.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                double maxVal = 1.0;
                for (var item in monthlyData) {
                  final due = (item['due'] as num?)?.toDouble() ?? 0.0;
                  if (due > maxVal) maxVal = due;
                }

                final displayData = monthlyData.take(6).toList().reversed.toList();

                return SizedBox(
                  height: 190,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(displayData.length, (index) {
                      final item = displayData[index];
                      final monthName = (item['month'] as String? ?? '').split(' ').first;
                      final dueVal = (item['due'] as num?)?.toDouble() ?? 0.0;
                      final isActive = index == displayData.length - 1;
                      final heightRatio = (dueVal / maxVal).clamp(0.12, 1.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Rs.${dueVal.toStringAsFixed(0)}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.normal,
                              color: isDark
                                  ? lavender.withValues(alpha: 0.7)
                                  : spaceCadet.withValues(alpha: 0.6),
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
                                      ? spaceCadet
                                      : lavender),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthName,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? (isDark ? Colors.white : oxfordBlue)
                                  : (isDark
                                      ? lavender.withValues(alpha: 0.7)
                                      : spaceCadet.withValues(alpha: 0.6)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // --- 5. REAL 3-COLUMN METRIC CARDS ---
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsService.getCustomerAnalytics(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {};
                final totalDue = (data['totalDue'] as num?)?.toDouble() ?? 0.0;
                final averageDue = (data['averageDue'] as num?)?.toDouble() ?? 0.0;
                final highestDue = (data['highestDue'] as num?)?.toDouble() ?? 0.0;

                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.trending_up_rounded,
                        value: 'Rs. ${averageDue.toStringAsFixed(0)}',
                        label: LanguageController.isUrdu ? 'اوسط بقایا' : 'Average Due',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.account_balance_wallet_outlined,
                        value: 'Rs. ${totalDue.toStringAsFixed(0)}',
                        label: LanguageController.isUrdu ? 'کل بقایا' : 'Total Due',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.arrow_upward_rounded,
                        value: 'Rs. ${highestDue.toStringAsFixed(0)}',
                        label: LanguageController.isUrdu ? 'سب سے زیادہ بقایا' : 'Highest Due',
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // --- 6. REAL OVERDUE PAYMENTS SECTION ---
            _buildOverdueCustomersSection(isDark),

            const SizedBox(height: 20),

            // --- 7. WORKING EXPANDABLE LIST TILE CARDS ---
            _buildListTileCard(
              title: LanguageController.isUrdu ? 'ٹاپ گاہکوں کا جائزہ' : 'Top Customers Overview',
              isDark: isDark,
              trailingIcon: _showTopCustomers
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              onTap: () {
                setState(() {
                  _showTopCustomers = !_showTopCustomers;
                });
              },
            ),

            if (_showTopCustomers) ...[
              const SizedBox(height: 12),
              _buildTopCustomersList(isDark),
            ],

            const SizedBox(height: 24),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? jordyBlue : yinMnBlue),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : oxfordBlue,
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
              color: isDark ? lavender.withValues(alpha: 0.7) : spaceCadet.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCustomersSection(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getOverdueCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final overdueCustomers = snapshot.data ?? [];
        if (overdueCustomers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    LanguageController.isUrdu ? 'کوئی بقایا ادائگیاں نہیں! زبردست کام!' : 'No overdue payments! Great job!',
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
            color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Text(
                LanguageController.isUrdu ? 'زیر التوا ادائگیاں (30+ دن)' : 'Overdue Payments (30+ days)',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : oxfordBlue,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                overdueCustomers.length,
                (index) {
                  final customer = overdueCustomers[index];
                  final days = customer['daysSinceLastTransaction'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Text(
                              customer['name'] ?? (LanguageController.isUrdu ? 'نامعلوم' : 'Unknown'),
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : oxfordBlue,
                              ),
                            ),
                            Text(
                              LanguageController.isUrdu ? '$days دن اوورڈیو' : '$days days overdue',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? lavender.withValues(alpha: 0.7)
                                    : spaceCadet.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rs. ${(customer['due'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopCustomersList(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getTopCustomers(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: yinMnBlue));
        }

        final topCustomers = snapshot.data ?? [];
        if (topCustomers.isEmpty) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
            ),
          ),
          child: Column(
            children: List.generate(
              topCustomers.length,
              (index) {
                final c = topCustomers[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: yinMnBlue,
                    radius: 14,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  title: Text(
                    c['name'] ?? (LanguageController.isUrdu ? 'نامعلوم' : 'Unknown'),
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : oxfordBlue,
                    ),
                  ),
                  subtitle: Text(
                    c['phone'] ?? (LanguageController.isUrdu ? 'کوئی فون نہیں' : 'No Phone'),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: isDark ? lavender.withValues(alpha: 0.7) : spaceCadet.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Text(
                    'Rs. ${(c['due'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : oxfordBlue,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
        color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : oxfordBlue,
          ),
        ),
        trailing: Icon(
          trailingIcon,
          color: isDark ? jordyBlue : yinMnBlue,
        ),
        onTap: onTap,
      ),
    );
  }
}