import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/controller/language_controller.dart';

class NavItem {
  final String label;
  final String urduLabel;
  final String? subtitle;
  final String? urduSubtitle;
  final IconData icon;
  final String route;
  final String section;
  final Color? customColor;

  const NavItem({
    required this.label,
    required this.urduLabel,
    this.subtitle,
    this.urduSubtitle,
    required this.icon,
    required this.route,
    required this.section,
    this.customColor,
  }); 
}

final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) return false;

  try {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('is_super_admin')
        .eq('id', userId)
        .maybeSingle();

    if (res != null && res['is_super_admin'] == true) {
      return true;
    }
  } catch (e) {
    debugPrint('Error checking super admin status: $e');
  }
  return false; 
});

class AppSidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  ConsumerState<AppSidebar> createState() => _SidebarState(); 
}

class _SidebarState extends ConsumerState<AppSidebar> {
  bool _isExplicitlyExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const double collapsedWidth = 80;

  List<NavItem> _getAllNavItems(bool isSuperAdmin) {
    return [
      const NavItem(
        label: 'Dashboard',
        urduLabel: 'ڈیش بورڈ',
        subtitle: 'Business Overview',
        urduSubtitle: 'کاروباری جائزہ',
        icon: Icons.dashboard_rounded,
        route: '/',
        section: 'Business',
      ),
      if (isSuperAdmin)
        const NavItem(
          label: 'Super Admin',
          urduLabel: 'سুপر ایڈمن',
          subtitle: 'Administration',
          urduSubtitle: 'انتظامیہ',
          icon: Icons.admin_panel_settings_rounded,
          route: '/admin',
          section: 'Business',
          customColor: Colors.redAccent,
        ),
      const NavItem(
        label: 'Stock Book',
        urduLabel: 'اسٹاک بک',
        subtitle: 'Products & Stock',
        urduSubtitle: 'پروڈکٹس اور اسٹاک',
        icon: Icons.inventory_2_rounded,
        route: '/inventory',
        section: 'Business',
      ),
      const NavItem(
        label: 'Staff Book',
        urduLabel: 'اسٹاف بک',
        subtitle: 'Manage Team',
        urduSubtitle: 'ٹیم کا نظم کریں',
        icon: Icons.badge_rounded,
        route: '/staff',
        section: 'Business',
      ),
      const NavItem(
        label: 'Suppliers',
        urduLabel: 'سپلائرز',
        subtitle: 'Vendor Directory',
        urduSubtitle: 'فروشوں کی ڈائرکٹری',
        icon: Icons.business_rounded,
        route: '/suppliers',
        section: 'Business',
      ),
      const NavItem(
        label: 'Digital Store',
        urduLabel: 'ڈیجیٹل اسٹور',
        subtitle: 'Storefront',
        urduSubtitle: 'اسٹور فرنٹ',
        icon: Icons.storefront_rounded,
        route: '/store',
        section: 'Business',
      ),
      const NavItem(
        label: 'Invoices',
        urduLabel: 'انوائسز',
        subtitle: 'Bill Book',
        urduSubtitle: 'بل بک',
        icon: Icons.receipt_long_rounded,
        route: '/bill-book',
        section: 'Billing',
      ),
      const NavItem(
        label: 'Expenses',
        urduLabel: 'اخراجات',
        subtitle: 'Track Spending',
        urduSubtitle: 'اخراجات کا سراغ لگائیں',
        icon: Icons.account_balance_wallet_rounded,
        route: '/expense_screen',
        section: 'Billing',
      ),
      const NavItem(
        label: 'Accounts',
        urduLabel: 'اکاؤنٹس',
        subtitle: 'Cash & Bank',
        urduSubtitle: 'نقد اور بینک',
        icon: Icons.account_balance_rounded,
        route: '/accounts',
        section: 'Billing',
      ),
      const NavItem(
        label: 'Analytics',
        urduLabel: 'تجزیات',
        subtitle: 'Reports & Metrics',
        urduSubtitle: 'رپورٹس اور میٹرکس',
        icon: Icons.analytics_rounded,
        route: '/inventory/analytics',
        section: 'Reports',
      ),
      const NavItem(
        label: 'Unified Ledger',
        urduLabel: 'متحدہ لیجر',
        subtitle: 'Transactions',
        urduSubtitle: 'لین دین',
        icon: Icons.menu_book_rounded,
        route: '/ledger',
        section: 'Reports',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'User';
    final isSuperAdminAsync = ref.watch(isSuperAdminProvider);
    
    final isSuperAdmin = isSuperAdminAsync.maybeWhen(
      data: (val) => val,
      orElse: () => false,
    );

    final allItems = _getAllNavItems(isSuperAdmin);
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isSettingsSelected = currentRoute == '/settings' || currentRoute.startsWith('/settings/');

    final bool fullyExpanded = _isExplicitlyExpanded || !widget.isCollapsed;

    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((item) =>
            item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.urduLabel.contains(_searchQuery) ||
            (item.subtitle?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (item.urduSubtitle?.contains(_searchQuery) ?? false)).toList();

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: fullyExpanded ? double.infinity : collapsedWidth,
        height: double.infinity,
        color: AppColors.darkBackground,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.darkSurface.withValues(alpha: 0.88),
                        AppColors.darkBackground.withValues(alpha: 0.94),
                      ],
                    ),
                  ),
                  child: Column(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      SidebarHeader(
                        fullyExpanded: fullyExpanded,
                        userEmail: userEmail,
                        onToggleExpand: () {
                          setState(() {
                            _isExplicitlyExpanded = !_isExplicitlyExpanded;
                          });
                          if (widget.onToggleCollapse != null) {
                            widget.onToggleCollapse!();
                          }
                        },
                      ),
                      if (fullyExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.darkBackground.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              textDirection: LanguageController.contentTextDirection,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: LanguageController.isUrdu ? 'تلاش کریں...' : 'Search navigation...',
                                hintTextDirection: LanguageController.contentTextDirection,
                                hintStyle: TextStyle(color: AppColors.lavender.withValues(alpha: 0.4), fontSize: 13),
                                prefixIcon: Icon(Icons.search_rounded, color: AppColors.jordyBlue.withValues(alpha: 0.7), size: 18),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Divider(height: 1, color: AppColors.darkBorder.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                          children: [
                            _buildGroupSection('Business', LanguageController.isUrdu ? 'کاروبار' : 'Business', filteredItems, currentRoute, fullyExpanded),
                            _buildGroupSection('Billing', LanguageController.isUrdu ? 'بلنگ' : 'Billing', filteredItems, currentRoute, fullyExpanded),
                            _buildGroupSection('Reports', LanguageController.isUrdu ? 'رپورٹس' : 'Reports', filteredItems, currentRoute, fullyExpanded),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.darkBorder.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      SidebarFooter(
                        fullyExpanded: fullyExpanded,
                        userEmail: userEmail,
                        isSettingsSelected: isSettingsSelected,
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(String sectionName, String displaySectionName, List<NavItem> items, String currentRoute, bool fullyExpanded) {
    final sectionItems = items.where((item) => item.section == sectionName).toList();
    if (sectionItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: LanguageController.contentTextDirection,
      children: [
        if (fullyExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Text(
              displaySectionName.toUpperCase(),
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.jordyBlue.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        ...sectionItems.map((item) => NavigationItemWidget(
              item: item,
              currentRoute: currentRoute,
              fullyExpanded: fullyExpanded,
            )),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  } 
}

class SidebarHeader extends StatelessWidget {
  final bool fullyExpanded;
  final String userEmail;
  final VoidCallback onToggleExpand;

  const SidebarHeader({
    super.key,
    required this.fullyExpanded,
    required this.userEmail,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: fullyExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: AppColors.jordyBlue.withValues(alpha: 0.4), width: 1.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (fullyExpanded) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Text(
                    LanguageController.isUrdu ? 'ڈیجیٹل کھاتہ' : 'Digital Khata',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LanguageController.isUrdu ? 'انٹرپرائز ورک اسپیس' : 'Enterprise Workspace',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.lavender.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.menu_open_rounded,
                    color: AppColors.jordyBlue.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox.shrink(),
          ],
        ],
      ),
    );
  } 
}

class NavigationItemWidget extends StatefulWidget {
  final NavItem item;
  final String currentRoute;
  final bool fullyExpanded;

  const NavigationItemWidget({
    super.key,
    required this.item,
    required this.currentRoute,
    required this.fullyExpanded,
  });

  @override
  State<NavigationItemWidget> createState() => _NavigationItemWidgetState(); 
}

class _NavigationItemWidgetState extends State<NavigationItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _animationController.forward();
    await _animationController.reverse();

    if (!mounted) return;

    final router = GoRouter.of(context);
    Navigator.of(context).maybePop(); // Close drawer first
    
    if (widget.currentRoute != widget.item.route) {
      router.go(widget.item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExactRoot = widget.item.route == '/';
    final isSelected = isExactRoot
        ? widget.currentRoute == '/'
        : widget.currentRoute == widget.item.route || widget.currentRoute.startsWith('${widget.item.route}/');

    final itemColor = widget.item.customColor ?? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.92));
    final labelText = LanguageController.isUrdu ? widget.item.urduLabel : widget.item.label;
    final subtitleText = LanguageController.isUrdu ? widget.item.urduSubtitle : widget.item.subtitle;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.yinMnBlue.withValues(alpha: 0.6),
                    AppColors.jordyBlue.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: _handleTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.fullyExpanded ? AppSpacing.lg : 0,
                vertical: 11,
              ),
              child: Row(
                mainAxisAlignment: widget.fullyExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Icon(
                    widget.item.icon,
                    color: itemColor,
                    size: 22,
                  ),
                  if (widget.fullyExpanded) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Text(
                            labelText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 14.5,
                              height: 1.25,
                              letterSpacing: 0.15,
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.94),
                            ),
                          ),
                          if (subtitleText != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: AppColors.lavender.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } 
}

class SidebarFooter extends StatefulWidget {
  final bool fullyExpanded;
  final String userEmail;
  final bool isSettingsSelected;
  final String currentRoute;

  const SidebarFooter({
    super.key,
    required this.fullyExpanded,
    required this.userEmail,
    required this.isSettingsSelected,
    required this.currentRoute,
  });

  @override
  State<SidebarFooter> createState() => _SidebarFooterState(); 
}

class _SidebarFooterState extends State<SidebarFooter>
    with TickerProviderStateMixin {
  late AnimationController _settingsController;
  late Animation<double> _settingsScale;
  late AnimationController _logoutController;
  late Animation<double> _logoutScale;

  @override
  void initState() {
    super.initState();
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _settingsScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _settingsController, curve: Curves.easeInOut),
    );

    _logoutController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _logoutScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _logoutController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _settingsController.dispose();
    _logoutController.dispose();
    super.dispose();
  }

  void _handleSettingsTap() async {
    await _settingsController.forward();
    await _settingsController.reverse();

    if (!mounted) return;
    Navigator.of(context).maybePop(); // Close drawer first
    if (widget.currentRoute != '/settings') {
      context.push('/settings');
    }
  }

  void _handleLogoutTap() async {
    await _logoutController.forward();
    await _logoutController.reverse();

    if (!mounted) return;
    logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        textDirection: LanguageController.contentTextDirection,
        children: [
          ScaleTransition(
            scale: _settingsScale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                color: widget.isSettingsSelected ? AppColors.yinMnBlue.withValues(alpha: 0.4) : Colors.transparent,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: _handleSettingsTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.fullyExpanded ? AppSpacing.lg : 0,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisAlignment: widget.fullyExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          color: widget.isSettingsSelected ? Colors.white : Colors.white.withValues(alpha: 0.92),
                          size: 22,
                        ),
                        if (widget.fullyExpanded) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              LanguageController.isUrdu ? 'ترتیبات' : 'Settings',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontWeight: widget.isSettingsSelected ? FontWeight.w800 : FontWeight.w700,
                                fontSize: 14.5,
                                height: 1.25,
                                letterSpacing: 0.15,
                                color: Colors.white.withValues(alpha: 0.94),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ScaleTransition(
            scale: _logoutScale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                onTap: _handleLogoutTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.fullyExpanded ? AppSpacing.lg : 0,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisAlignment: widget.fullyExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      if (widget.fullyExpanded) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            LanguageController.isUrdu ? 'لاگ آؤٹ' : 'Logout',
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              color: Colors.redAccent.shade200,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              height: 1.25,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } 
}