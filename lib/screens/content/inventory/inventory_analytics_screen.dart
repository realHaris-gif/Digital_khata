import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
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
  const InventoryAnalyticsScreen({Key? key}) : super(key: key);

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(analyticsProductsProvider(userId));
    ref.invalidate(analyticsCategoriesProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Analytics'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref, userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : ref.watch(analyticsProductsProvider(userId)).when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No product data available for analytics.',
                        style: TextStyle(color: Colors.grey),
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
                    onRefresh: () async => _refresh(ref, userId),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Financial Valuation Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Valuation & Profit Margin',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Retail Valuation',
                                          style: TextStyle(color: Colors.grey)),
                                      Text(
                                        'Rs. ${totalRetailVal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Cost Valuation',
                                          style: TextStyle(color: Colors.grey)),
                                      Text(
                                        'Rs. ${totalCostVal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Potential Profit Margin',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal),
                                      ),
                                      Text(
                                        'Rs. ${totalPotentialProfit.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Inventory Health Metrics
                          Row(
                            children: [
                              Expanded(
                                child: InventorySummaryCard(
                                  title: 'Low Stock Alert',
                                  value: '$lowStockCount',
                                  icon: Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InventorySummaryCard(
                                  title: 'Out of Stock',
                                  value: '$outOfStockCount',
                                  icon: Icons.remove_shopping_cart,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Highest Stock Quantity Products
                          const Text(
                            'Top Stock Quantities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...topStockItems.map((prod) {
                            final double maxStock =
                                topStockItems.first.currentStock > 0
                                    ? topStockItems.first.currentStock
                                    : 1.0;
                            final double progress =
                                (prod.currentStock / maxStock).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        prod.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${prod.currentStock.toStringAsFixed(0)} ${prod.unit}',
                                        style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.teal,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              ),
    );
  }
}