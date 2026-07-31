import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/widgets/inventory/inventory_widgets.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getProductById(productId);
});

final productMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, productId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getProductMovements(productId);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  void _refresh(WidgetRef ref) {
    ref.invalidate(productDetailProvider(productId));
    ref.invalidate(productMovementsProvider(productId));
  }

  Future<void> _showMovementModal(
    BuildContext context,
    WidgetRef ref,
    Product product,
    StockMovementType type,
  ) async {
    final qtyController = TextEditingController();
    final refController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record ${type.displayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: type == StockMovementType.adjustment
                        ? 'New Absolute Quantity'
                        : 'Quantity (${product.unit})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    if (double.tryParse(val) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: 'Reference / Invoice # (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes / Reason (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id ?? '';
                    final repo = ref.read(inventoryRepoProvider);

                    await repo.recordStockMovement(
                      userId: userId,
                      productId: product.id,
                      type: type,
                      quantity: double.parse(qtyController.text.trim()),
                      reference: refController.text.trim().isEmpty
                          ? null
                          : refController.text.trim(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh(ref);
                  },
                  child: const Text(
                    'Save Movement',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              final userId =
                  Supabase.instance.client.auth.currentUser?.id ?? '';
              final repo = ref.read(inventoryRepoProvider);

              if (val == 'duplicate') {
                await repo.duplicateProduct(productId, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product copied successfully!')),
                  );
                  context.pop(true);
                }
              } else if (val == 'delete') {
                await repo.deleteProduct(productId);
                if (context.mounted) context.pop(true);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Duplicate Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Product'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(ref),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header Card
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              StockBadge(product: product),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SKU: ${product.sku ?? "N/A"} • Barcode: ${product.barcode ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              product.description!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stock & Price Summary Grid
                  Row(
                    children: [
                      Expanded(
                        child: InventorySummaryCard(
                          title: 'Current Stock',
                          value:
                              '${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                          icon: Icons.inventory_outlined,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InventorySummaryCard(
                          title: 'Selling Price',
                          value:
                              'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
                          icon: Icons.sell_outlined,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InventorySummaryCard(
                          title: 'Purchase Price',
                          value:
                              'Rs. ${product.purchasePrice.toStringAsFixed(2)}',
                          icon: Icons.shopping_bag_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InventorySummaryCard(
                          title: 'Total Stock Value',
                          value:
                              'Rs. ${product.totalStockValue.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stock Actions Buttons Grid
                  const Text(
                    'Quick Stock Adjustments',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showMovementModal(
                            context,
                            ref,
                            product,
                            StockMovementType.inStock,
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Stock In',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showMovementModal(
                            context,
                            ref,
                            product,
                            StockMovementType.outStock,
                          ),
                          icon: const Icon(Icons.remove, color: Colors.white),
                          label: const Text('Stock Out',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMovementModal(
                            context,
                            ref,
                            product,
                            StockMovementType.adjustment,
                          ),
                          icon: const Icon(Icons.tune),
                          label: const Text('Adjust'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMovementModal(
                            context,
                            ref,
                            product,
                            StockMovementType.returnStock,
                          ),
                          icon: const Icon(Icons.replay),
                          label: const Text('Return'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stock Movements History
                  const Text(
                    'Stock Activity History',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ref.watch(productMovementsProvider(productId)).when(
                        data: (movements) {
                          if (movements.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No stock changes recorded yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: movements.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return MovementTile(
                                movement: movements[index],
                              );
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }
}