import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
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
  const InventoryDashboardScreen({Key? key}) : super(key: key);

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(dashboardProductsProvider(userId));
    ref.invalidate(recentMovementsProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
            onPressed: () => context.push('/inventory/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref, userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : RefreshIndicator(
              onRefresh: () async => _refresh(ref, userId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InventorySummaryCard(
                                        title: 'Total Products',
                                        value: '$totalProducts',
                                        icon: Icons.inventory_2_outlined,
                                        color: Colors.blue,
                                        onTap: () =>
                                            context.push('/inventory/products'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InventorySummaryCard(
                                        title: 'Inventory Value',
                                        value:
                                            'Rs. ${totalValue.toStringAsFixed(0)}',
                                        icon: Icons.account_balance_wallet,
                                        color: Colors.teal,
                                        onTap: () =>
                                            context.push('/inventory/analytics'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InventorySummaryCard(
                                        title: 'Low Stock',
                                        value: '$lowStockCount',
                                        icon: Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        onTap: () => context
                                            .push('/inventory/low-stock'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InventorySummaryCard(
                                        title: 'Out of Stock',
                                        value: '$outOfStockCount',
                                        icon: Icons.remove_shopping_cart,
                                        color: Colors.red,
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
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text('${l10n.error}: $e'),
                        ),

                    const SizedBox(height: 24),

                    // Quick Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final res =
                                  await context.push('/inventory/products');
                              if (res == true) _refresh(ref, userId);
                            },
                            icon: const Icon(Icons.list_alt,
                                color: Colors.white),
                            label: const Text(
                              'Product List',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                context.push('/inventory/analytics'),
                            icon: const Icon(Icons.analytics_outlined,
                                color: Colors.white),
                            label: const Text(
                              'Analytics',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Stock Movements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => context.push('/inventory/products'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Recent Stock Movements List
                    ref.watch(recentMovementsProvider(userId)).when(
                          data: (movements) {
                            if (movements.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No stock activity recorded yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: movements.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 64,
                              ),
                              itemBuilder: (context, index) {
                                final movement = movements[index];
                                return MovementTile(movement: movement);
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('${l10n.error}: $e'),
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
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}