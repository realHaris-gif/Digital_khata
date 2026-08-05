import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/inventory/inventory_widgets.dart';

// Providers for Inventory Dashboard State
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final dashboardProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getProducts(userId: userId, limit: 500);
});

final recentMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getRecentMovements(userId, limit: 10);
});

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(dashboardProductsProvider(userId));
    ref.invalidate(recentMovementsProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.yinMnBlue,
              ),
        ),
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
              LanguageController.isUrdu ? 'انوینٹری ڈیش بورڈ' : l10n.appTitle,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.oxfordBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.category_outlined, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                tooltip: LanguageController.isUrdu ? 'زمرے' : 'Categories',
                onPressed: () => context.push('/inventory/categories'),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                onPressed: () => _refresh(ref, userId),
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
              : RefreshIndicator(
                  color: AppColors.yinMnBlue,
                  onRefresh: () async => _refresh(ref, userId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        // KPI Cards Grid
                        ref.watch(dashboardProductsProvider(userId)).when(
                              data: (products) {
                                final totalProducts = products.length;
                                final totalValue = products.fold<double>(
                                    0.0, (sum, p) => sum + p.totalRetailValue);
                                final lowStockCount = products
                                    .where((p) => p.isLowStock)
                                    .length;
                                final outOfStockCount = products
                                    .where((p) => p.isOutOfStock)
                                    .length;

                                return Column(
                                  textDirection: LanguageController.contentTextDirection,
                                  children: [
                                    Row(
                                      textDirection: LanguageController.contentTextDirection,
                                      children: [
                                        Expanded(
                                          child: InventorySummaryCard(
                                            title: LanguageController.isUrdu ? 'کل پروڈکٹس' : 'Total Products',
                                            value: '$totalProducts',
                                            icon: Icons.inventory_2_outlined,
                                            color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                            onTap: () =>
                                                context.push('/inventory/products'),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: InventorySummaryCard(
                                            title: LanguageController.isUrdu ? 'انوینٹری کی قیمت' : 'Inventory Value',
                                            value:
                                                'Rs. ${totalValue.toStringAsFixed(0)}',
                                            icon: Icons.account_balance_wallet,
                                            color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                            onTap: () =>
                                                context.push('/inventory/analytics'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      textDirection: LanguageController.contentTextDirection,
                                      children: [
                                        Expanded(
                                          child: InventorySummaryCard(
                                            title: LanguageController.isUrdu ? 'کم اسٹاک' : 'Low Stock',
                                            value: '$lowStockCount',
                                            icon: Icons.warning_amber_rounded,
                                            color: AppColors.warning,
                                            onTap: () => context
                                                .push('/inventory/low-stock'),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: InventorySummaryCard(
                                            title: LanguageController.isUrdu ? 'اسٹاک ختم' : 'Out of Stock',
                                            value: '$outOfStockCount',
                                            icon: Icons.remove_shopping_cart,
                                            color: AppColors.danger,
                                            onTap: () => context
                                                .push('/inventory/low-stock'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(
                                height: 160,
                                child: Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
                              ),
                              error: (e, _) => Text(
                                '${l10n.error}: $e',
                                textDirection: LanguageController.contentTextDirection,
                              ),
                            ),

                        const SizedBox(height: AppSpacing.xl),

                        // Quick Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: AppColors.yinMnBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                onPressed: () async {
                                  final res =
                                      await context.push('/inventory/products');
                                  if (res == true) _refresh(ref, userId);
                                },
                                icon: const Icon(Icons.list_alt,
                                    color: Colors.white),
                                label: Text(
                                  LanguageController.isUrdu ? 'پروڈکٹ کی فہرست' : 'Product List',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: AppColors.spaceCadet,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                onPressed: () =>
                                    context.push('/inventory/analytics'),
                                icon: const Icon(Icons.analytics_outlined,
                                    color: Colors.white),
                                label: Text(
                                  LanguageController.isUrdu ? 'تجزیات' : 'Analytics',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Recent Activity Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Text(
                              LanguageController.isUrdu ? 'حالیہ اسٹاک کی نقل و حرکت' : 'Recent Stock Movements',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                              onPressed: () => context.push('/inventory/products'),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Recent Stock Movements List
                        ref.watch(recentMovementsProvider(userId)).when(
                              data: (movements) {
                                if (movements.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Center(
                                      child: Text(
                                        LanguageController.isUrdu ? 'ابھی تک کوئی اسٹاک سرگرمی درج نہیں ہوئی۔' : 'No stock activity recorded yet.',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: movements.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    indent: 64,
                                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                                  ),
                                  itemBuilder: (context, index) {
                                    final movement = movements[index];
                                    return MovementTile(movement: movement);
                                  },
                                );
                              },
                              loading: () =>
                                  const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
                              error: (e, _) => Text(
                                '${l10n.error}: $e',
                                textDirection: LanguageController.contentTextDirection,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final res = await context.push('/inventory/add-product');
              if (res == true) _refresh(ref, userId);
            },
            backgroundColor: AppColors.yinMnBlue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              LanguageController.isUrdu ? 'پروڈکٹ شامل کریں' : 'Add Product',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}