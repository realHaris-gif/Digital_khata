import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/services.dart';
import 'package:digital_khata/widgets/common/notification_bell.dart';
import 'package:digital_khata/screens/content/notification/notification_screen.dart'; 
import 'package:digital_khata/widgets/payment/collect_payment_dialog.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  Map<String, double> _cachedTotals = {};
  bool _isLoadingTotals = true;

  // New Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    try {
      final totals = await _databaseService.getAllPeopleWithTotals();
      if (mounted) {
        setState(() {
          _cachedTotals = totals;
          _isLoadingTotals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTotals = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userEmail = _authService.currentUser?.email ?? "User";
    final isDark = ThemeController.isDarkMode;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: LanguageController.contentTextDirection,
          children: [
            // Top Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      size: 28,
                      color: isDark ? jordyBlue : spaceCadet,
                    ),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Row(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    const NotificationBell(),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: LanguageController.isUrdu ? (isDark ? 'لائٹ موڈ پر سوئچ کریں' : 'ڈارک موڈ پر سوئچ کریں') : (isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                      onPressed: () {
                        setState(() {
                          ThemeController.toggleTheme();
                        });
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: isDark
                            ? const Icon(
                                Icons.nightlight_round,
                                key: ValueKey('dark_moon'),
                                color: jordyBlue,
                              )
                            : const Icon(
                                Icons.wb_sunny_rounded,
                                key: ValueKey('light_sun'),
                                color: yinMnBlue,
                              ),
                      ),
                    ),
                    PopupMenuButton<Locale>(
                      icon: Icon(
                        Icons.language,
                        color: isDark ? jordyBlue : spaceCadet,
                      ),
                      tooltip: LanguageController.isUrdu ? 'زبان تبدیل کریں' : 'Change Language',
                      onSelected: (Locale locale) {
                        LanguageController.changeLanguage(locale);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                        const PopupMenuItem<Locale>(
                          value: Locale('en'),
                          child: Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              Text('🇬🇧 '),
                              SizedBox(width: 8),
                              Text('English'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<Locale>(
                          value: Locale('ur'),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Text('🇵🇰 '),
                              SizedBox(width: 8),
                              Text('اردو (Urdu)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        logout(context);
                      },
                      icon: Icon(
                        Icons.logout_outlined,
                        color: isDark ? jordyBlue : spaceCadet,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User Welcome Banner Card
            Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            jordyBlue,
                            yinMnBlue,
                            spaceCadet,
                          ],
                          transform: GradientRotation(pi / 4),
                        ),
                      ),
                    ),
                    const Icon(Icons.person, color: Colors.white),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    Text(
                      LanguageController.isUrdu ? 'خوش آمدید،' : 'Welcome,',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? jordyBlue : spaceCadet.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      userEmail,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : oxfordBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Total Balance Card with Blue Skeleton Loading State
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.peopleStream,
              builder: (context, peopleSnapshot) {
                if (peopleSnapshot.connectionState == ConnectionState.waiting &&
                    !peopleSnapshot.hasData &&
                    _isLoadingTotals) {
                  return _buildBalanceSkeletonCard(isDark);
                }

                final people = peopleSnapshot.data ?? [];

                double totalDue = 0;
                double lowestDue = double.infinity;
                double highestDue = 0;
                String lowestPerson = '';
                String highestPerson = '';

                for (var person in people) {
                  final name = person['name'] ?? '';
                  final personId = person['id']?.toString() ?? '';
                  final personTotal = _cachedTotals[personId] ?? 0.0;

                  totalDue += personTotal;

                  if (personTotal < lowestDue) {
                    lowestDue = personTotal;
                    lowestPerson = name;
                  }

                  if (personTotal > highestDue) {
                    highestDue = personTotal;
                    highestPerson = name;
                  }
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        spaceCadet,
                        yinMnBlue,
                        jordyBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : spaceCadet.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                        l10n.totalBalance,
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(
                          fontSize: 16,
                          color: lavender,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rs. ${totalDue.toStringAsFixed(2)}",
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 34,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'کمترین بقایا' : 'Lowest Due',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: lavender,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                "Rs. ${lowestDue == double.infinity ? 0.0 : lowestDue.toStringAsFixed(2)}",
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                lowestPerson,
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'سب سے زیادہ بقایا' : 'Highest Due',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: lavender,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                "Rs. ${highestDue.toStringAsFixed(2)}",
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                highestPerson,
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 1. KHATA SECTION
            // ==========================================
            Text(
              LanguageController.isUrdu ? 'کھاتہ' : 'Khata',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? jordyBlue : spaceCadet,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? jordyBlue.withOpacity(0.2) : lavender,
                ),
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'پارٹی' : 'Party', icon: Icons.person_rounded, color: yinMnBlue, route: '/ledger'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'کیش' : 'Cash', icon: Icons.account_balance_wallet_rounded, color: yinMnBlue, route: '/accounts'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'اسٹاک' : 'Stock', icon: Icons.inventory_2_rounded, color: yinMnBlue, route: '/inventory'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'بل' : 'Bill', icon: Icons.receipt_long_rounded, color: yinMnBlue, route: '/bill-book'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'اسٹاف' : 'Staff', icon: Icons.badge_rounded, color: yinMnBlue, route: '/staff'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'خرچہ' : 'Expense', icon: Icons.payments_rounded, color: yinMnBlue, route: '/expense_screen'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. PAYMENTS SECTION (POS & QR CODE)
            // ==========================================
            Text(
              LanguageController.isUrdu ? 'ادائگیاں' : 'Payments',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? jordyBlue : spaceCadet,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CollectPaymentModal(isPOS: true),
                      );
                    },
                    child: Container(
                      height: 145,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [spaceCadet, yinMnBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: spaceCadet.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.point_of_sale_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                'POS',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                LanguageController.isUrdu ? 'اپنے فون پر کارڈ کی ادائگیاں قبول کریں' : 'Accept card payments on your phone',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  color: lavender,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CollectPaymentModal(isPOS: false),
                      );
                    },
                    child: Container(
                      height: 145,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [yinMnBlue, jordyBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: yinMnBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                'QR',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                LanguageController.isUrdu ? 'اپنا QR شیئر کریں اور ادائیگی حاصل کریں' : 'Share your QR and get paid',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  color: lavender,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. MORE TOOLS SECTION
            // ==========================================
            Text(
              LanguageController.isUrdu ? 'مزید' : 'More',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? jordyBlue : spaceCadet,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? jordyBlue.withOpacity(0.2) : lavender,
                ),
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'ڈیجیٹل اسٹور' : 'Digital Store', icon: Icons.storefront_rounded, color: yinMnBlue, route: '/store'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'بزنس کارڈ' : 'Business Card', icon: Icons.groups_rounded, color: yinMnBlue, route: '/tools/business-card'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'کیلکولیٹر' : 'Calculator', icon: Icons.calculate_rounded, color: yinMnBlue, route: '/tools/calculator'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'سپلائرز' : 'Suppliers', icon: Icons.local_shipping_rounded, color: yinMnBlue, route: '/suppliers'),
                  _buildKhataCard(context, title: LanguageController.isUrdu ? 'ری سائیکل بن' : 'Recycle Bin', icon: Icons.delete_outline_rounded, color: yinMnBlue, route: '/recycle-bin'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSkeletonCard(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Container(
          width: double.infinity,
          height: 180,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? spaceCadet : lavender.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: 100, height: 16, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              Container(width: 180, height: 34, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Container(width: 90, height: 30, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                  Container(width: 90, height: 30, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKhataCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final isDark = ThemeController.isDarkMode;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? oxfordBlue : lavender.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: LanguageController.contentTextDirection,
          children: [
            Icon(
              icon,
              color: isDark ? jordyBlue : color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : oxfordBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}