import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:digital_khata/screens/content/home/main_home_screen.dart';
import 'package:digital_khata/screens/content/people/list_people_screen.dart';
import 'package:digital_khata/widgets/app_sidebar.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/controller/language_controller.dart';
import '../../content/expense/analytics_screen.dart';
import '../../content/expense/expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _onTabTapped(int newIndex) {
    if (index == newIndex) return;
    setState(() {
      index = newIndex;
    });
  }

  void _handleFabPressed() {
    switch (index) {
      case 0:
      case 1:
        context.push('/staff/add');
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'تجزیات کے اختیارات یا رپورٹ ایکسپورٹ۔' : 'Analytics options or report export.',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
        );
        break;
      case 3:
        context.push('/expense_screen');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? jordyBlue : yinMnBlue;
    final inactiveColor = isDark ? jordyBlue.withValues(alpha: 0.4) : spaceCadet.withValues(alpha: 0.45);
    final bgColor = isDark ? AppColors.darkBackground : AppColors.surface1;

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: yinMnBlue,
      child: Scaffold(
        backgroundColor: bgColor,
        drawer: const Drawer(
          child: AppSidebar(),
        ),
        extendBody: false,
        // CRITICAL FIX: Replace PageView with IndexedStack to prevent rendering conflicts
        // PageView caches children and causes screen blending when GoRouter pushes new routes
        // IndexedStack only renders the active child, preventing partial visibility of off-screen content
        body: RepaintBoundary(
          child: IndexedStack(
            index: index,
            children: [
              ColoredBox(color: bgColor, child: const MainHomeScreen()),
              ColoredBox(color: bgColor, child: const ListPeopleScreen()),
              ColoredBox(color: bgColor, child: const AnalyticsScreen()),
              ColoredBox(color: bgColor, child: const ExpenseScreen()),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.25) : AppColors.borderLight,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppColors.spaceCadet.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  _buildNavItem(
                    tabIndex: 0,
                    icon: Icons.home_rounded,
                    label: LanguageController.isUrdu ? 'ہوم' : 'Home',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    tabIndex: 1,
                    icon: Icons.people_alt_rounded,
                    label: LanguageController.isUrdu ? 'لوگ' : 'People',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  const SizedBox(width: 48), // Space for center FAB
                  _buildNavItem(
                    tabIndex: 2,
                    icon: Icons.analytics_rounded,
                    label: LanguageController.isUrdu ? 'تجزیات' : 'Analytics',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    tabIndex: 3,
                    icon: Icons.receipt_long_rounded,
                    label: LanguageController.isUrdu ? 'اخراجات' : 'Expenses',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: FloatingActionButton(
            elevation: 8,
            shape: const CircleBorder(),
            onPressed: _handleFabPressed,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    spaceCadet,
                    yinMnBlue,
                    jordyBlue,
                  ],
                  transform: GradientRotation(pi / 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: yinMnBlue.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                index == 3 ? Icons.post_add_rounded : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int tabIndex,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = index == tabIndex;

    return GestureDetector(
      onTap: () => _onTabTapped(tabIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              )
            : const BoxDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: LanguageController.contentTextDirection,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}