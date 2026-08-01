import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/helper/helper_function.dart';

class SidebarItemData {
  final String label;
  final IconData icon;
  final String route;
  final int? badgeCount;
  final Color? customColor;

  const SidebarItemData({
    required this.label,
    required this.icon,
    required this.route,
    this.badgeCount,
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

class AppSidebar extends ConsumerWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  static const double expandedWidth = 270;
  static const double collapsedWidth = 72;

  const AppSidebar({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  List<SidebarItemData> _getNavItems(bool isSuperAdmin) {
    return [
      const SidebarItemData(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/',
      ),
      if (isSuperAdmin)
        const SidebarItemData(
          label: 'Super Admin',
          icon: Icons.admin_panel_settings_outlined,
          route: '/admin',
          customColor: Colors.redAccent,
        ),
      const SidebarItemData(
        label: 'Bill Book (Invoices)',
        icon: Icons.receipt_long_outlined,
        route: '/bill-book',
      ),
      const SidebarItemData(
        label: 'Stock Book (Inventory)',
        icon: Icons.inventory_2_outlined,
        route: '/inventory',
      ),
      const SidebarItemData(
        label: 'Staff Book',
        icon: Icons.badge_outlined,
        route: '/staff',
      ),
      const SidebarItemData(
        label: 'Digital Store',
        icon: Icons.storefront_outlined,
        route: '/store',
      ),
      const SidebarItemData(
        label: 'Analytics',
        icon: Icons.analytics_outlined,
        route: '/inventory/analytics',
      ),
      const SidebarItemData(
        label: 'Expenses',
        icon: Icons.account_balance_wallet_outlined,
        route: '/expense_screen',
      ),
      const SidebarItemData(
        label: 'Suppliers',
        icon: Icons.business_outlined,
        route: '/suppliers',
      ),
      const SidebarItemData(
        label: 'Accounts',
        icon: Icons.account_balance_outlined,
        route: '/accounts',
      ),
      const SidebarItemData(
        label: 'Unified Ledger',
        icon: Icons.menu_book_outlined,
        route: '/ledger',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? 'User';
    final isSuperAdminAsync = ref.watch(isSuperAdminProvider);
    final isSuperAdmin = isSuperAdminAsync.value ?? false;

    final navItems = _getNavItems(isSuperAdmin);
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isSettingsSelected = currentRoute == '/settings' ||
        currentRoute.startsWith('/settings/');

    return Material(
      color: theme.colorScheme.surface,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isCollapsed ? collapsedWidth : expandedWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Khata',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (onToggleCollapse != null)
                      IconButton(
                        icon: Icon(
                          isCollapsed
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                        ),
                        onPressed: onToggleCollapse,
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Navigation Item List
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isExactRoot = item.route == '/';
                    final isSelected = isExactRoot
                        ? currentRoute == '/'
                        : currentRoute == item.route ||
                            currentRoute.startsWith('${item.route}/');

                    final itemColor = item.customColor ??
                        (isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant);

                    final tile = Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          leading: Icon(
                            item.icon,
                            color: itemColor,
                          ),
                          title: isCollapsed
                              ? null
                              : Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                          onTap: () {
                            Navigator.of(context).maybePop();
                            if (currentRoute != item.route) {
                              context.push(item.route);
                            }
                          },
                        ),
                      ),
                    );

                    if (isCollapsed) {
                      return Tooltip(
                        message: item.label,
                        child: tile,
                      );
                    }

                    return tile;
                  },
                ),
              ),

              const Divider(height: 1),

              // Bottom Section: Settings Gear Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: isSettingsSelected,
                      selectedTileColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.4),
                      leading: Icon(
                        Icons.settings_outlined,
                        color: isSettingsSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: isCollapsed
                          ? null
                          : Text(
                              'Settings',
                              style: TextStyle(
                                fontWeight: isSettingsSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSettingsSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        if (currentRoute != '/settings') {
                          context.push('/settings');
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Bottom Section: Logout Button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => logout(context),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: theme.colorScheme.error,
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}