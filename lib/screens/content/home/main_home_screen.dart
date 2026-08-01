import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/services.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 28),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
                                color: Colors.amber,
                              )
                            : const Icon(
                                Icons.wb_sunny_rounded,
                                key: ValueKey('light_sun'),
                                color: Colors.orangeAccent,
                              ),
                      ),
                    ),
                    PopupMenuButton<Locale>(
                      icon: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Change Language',
                      onSelected: (Locale locale) {
                        LanguageController.changeLanguage(locale);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                        const PopupMenuItem<Locale>(
                          value: Locale('en'),
                          child: Row(
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
                      icon: const Icon(Icons.logout_outlined),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User Welcome Banner Card
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.tertiary,
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.primary,
                          ],
                          transform: const GradientRotation(pi / 4),
                        ),
                      ),
                    ),
                    const Icon(Icons.person, color: Colors.white),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome,",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Total Balance Card
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.peopleStream,
              builder: (context, peopleSnapshot) {
                if (peopleSnapshot.connectionState == ConnectionState.waiting &&
                    !peopleSnapshot.hasData &&
                    _isLoadingTotals) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
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
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.tertiary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                      ],
                      transform: const GradientRotation(pi / 4),
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : Colors.grey.shade400,
                        blurRadius: 8,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.totalBalance,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rs. ${totalDue.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 34,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lowest Due",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                "Rs. ${lowestDue == double.infinity ? 0.0 : lowestDue.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                lowestPerson,
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
                            children: [
                              const Text(
                                "Highest Due",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                "Rs. ${highestDue.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                highestPerson,
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
              "Khata",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
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
                  _buildKhataCard(
                    context,
                    title: 'Party',
                    icon: Icons.person_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/ledger', // 👈 Fixed route to open Party Ledger
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Cash',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/accounts',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Stock',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/inventory',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Bill',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/bill-book',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Staff',
                    icon: Icons.badge_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/staff',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Expense',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/expense_screen',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. PAYMENTS SECTION (POS & QR CODE)
            // ==========================================
            Text(
              "Payments",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            Row(
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
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
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
                            children: const [
                              Text(
                                'POS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Accept card payments on your phone',
                                style: TextStyle(
                                  color: Colors.white70,
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
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
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
                            children: const [
                              Text(
                                'QR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Share your QR and get paid',
                                style: TextStyle(
                                  color: Colors.white70,
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
              "More",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
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
                  _buildKhataCard(
                    context,
                    title: 'Digital Store',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/store',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Business Card',
                    icon: Icons.store_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/tools/business-card',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Calculator',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/tools/calculator',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'Suppliers',
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/suppliers',
                  ),
                  _buildKhataCard(
                    context,
                    title: 'settings',
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFFF7A00),
                    route: '/settings',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
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
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFFFEDD5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}