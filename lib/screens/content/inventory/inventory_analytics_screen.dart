import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/inventory/inventory_widgets.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final analyticsProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getProducts(userId: userId, limit: 1000);
});

final analyticsCategoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getCategories(userId);
});

class InventoryAnalyticsScreen extends ConsumerWidget {
  const InventoryAnalyticsScreen({super.key});

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(analyticsProductsProvider(userId));
    ref.invalidate(analyticsCategoriesProvider(userId));
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
              LanguageController.isUrdu ? 'انوینٹری کے تجزیات' : 'Inventory Analytics',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.oxfordBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
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
              : ref.watch(analyticsProductsProvider(userId)).when(
                    data: (products) {
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            LanguageController.isUrdu ? 'تجزیات کے لیے کوئی پروڈکٹ ڈیٹا دستیاب نہیں ہے۔' : 'No product data available for analytics.',
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              color: isDark ? AppColors.lavender : AppColors.spaceCadet,
                            ),
                          ),
                        );
                      }

                      // Financial calculations
                      final double totalRetailVal = products.fold(
                          0.0, (sum, p) => sum + p.totalRetailValue);
                      final double totalCostVal = products.fold(
                          0.0, (sum, p) => sum + p.totalStockValue);
                      final double totalPotentialProfit =
                          totalRetailVal - totalCostVal;

                      final int lowStockCount =
                          products.where((p) => p.isLowStock).length;
                      final int outOfStockCount =
                          products.where((p) => p.isOutOfStock).length;

                      // Highest and lowest stock items
                      final sortedByStock = List<Product>.from(products)
                        ..sort((a, b) => b.currentStock.compareTo(a.currentStock));
                      final topStockItems = sortedByStock.take(5).toList();

                      return RefreshIndicator(
                        color: AppColors.yinMnBlue,
                        onRefresh: () async => _refresh(ref, userId),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              // Financial Valuation Card
                              Card(
                                elevation: 0,
                                color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                                  side: BorderSide(
                                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    textDirection: LanguageController.contentTextDirection,
                                    children: [
                                      Text(
                                        LanguageController.isUrdu ? 'تشخیص اور پرافٹ مارجن' : 'Valuation & Profit Margin',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.oxfordBlue,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        textDirection: LanguageController.contentTextDirection,
                                        children: [
                                          Text(
                                            LanguageController.isUrdu ? 'پرچون تشخیص' : 'Retail Valuation',
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                                color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6)),
                                          ),
                                          Text(
                                            'Rs. ${totalRetailVal.toStringAsFixed(2)}',
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        textDirection: LanguageController.contentTextDirection,
                                        children: [
                                          Text(
                                            LanguageController.isUrdu ? 'لاگت کی تشخیص' : 'Cost Valuation',
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                                color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6)),
                                          ),
                                          Text(
                                            'Rs. ${totalCostVal.toStringAsFixed(2)}',
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        height: 24,
                                        color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        textDirection: LanguageController.contentTextDirection,
                                        children: [
                                          Text(
                                            LanguageController.isUrdu ? 'ممکنہ پرافٹ مارجن' : 'Potential Profit Margin',
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${totalPotentialProfit.toStringAsFixed(2)}',
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Inventory Health Metrics
                              Row(
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Expanded(
                                    child: InventorySummaryCard(
                                      title: LanguageController.isUrdu ? 'کم اسٹاک الرٹ' : 'Low Stock Alert',
                                      value: '$lowStockCount',
                                      icon: Icons.warning_amber_rounded,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: InventorySummaryCard(
                                      title: LanguageController.isUrdu ? 'اسٹاک ختم' : 'Out of Stock',
                                      value: '$outOfStockCount',
                                      icon: Icons.remove_shopping_cart,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Highest Stock Quantity Products
                              Text(
                                LanguageController.isUrdu ? 'سب سے زیادہ اسٹاک مقدار' : 'Top Stock Quantities',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              ...topStockItems.map((prod) {
                                final double maxStock =
                                    topStockItems.first.currentStock > 0
                                        ? topStockItems.first.currentStock
                                        : 1.0;
                                final double progress =
                                    (prod.currentStock / maxStock).clamp(0.0, 1.0);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    textDirection: LanguageController.contentTextDirection,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        textDirection: LanguageController.contentTextDirection,
                                        children: [
                                          Text(
                                            prod.name,
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                                            ),
                                          ),
                                          Text(
                                            '${prod.currentStock.toStringAsFixed(0)} ${prod.unit}',
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: isDark
                                            ? AppColors.darkSurface
                                            : AppColors.lavender,
                                        color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
                    error: (e, _) => Center(
                      child: Text(
                        '${l10n.error}: $e',
                        textDirection: LanguageController.contentTextDirection,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}