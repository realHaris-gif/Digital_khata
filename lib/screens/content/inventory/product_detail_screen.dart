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

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

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
    final isDark = ThemeController.isDarkMode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? spaceCadet : Colors.white,
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
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  LanguageController.isUrdu ? '${type.displayName} درج کریں' : 'Record ${type.displayName}',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: qtyController,
                  style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                  textDirection: TextDirection.ltr,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: type == StockMovementType.adjustment
                        ? (LanguageController.isUrdu ? 'نیا مطلق مقدار' : 'New Absolute Quantity')
                        : (LanguageController.isUrdu ? 'مقدار (${product.unit})' : 'Quantity (${product.unit})'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return LanguageController.isUrdu ? 'مقدار درج کریں' : 'Enter quantity';
                    if (double.tryParse(val) == null) return LanguageController.isUrdu ? 'درست نمبر درج کریں' : 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: refController,
                  style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                  textDirection: LanguageController.contentTextDirection,
                  decoration: InputDecoration(
                    labelText: LanguageController.isUrdu ? 'حوالہ / انوائس # (اختیاری)' : 'Reference / Invoice # (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                  textDirection: LanguageController.contentTextDirection,
                  decoration: InputDecoration(
                    labelText: LanguageController.isUrdu ? 'نوٹس / وجہ (اختیاری)' : 'Notes / Reason (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: yinMnBlue,
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
                  child: Text(
                    LanguageController.isUrdu ? 'نقل و حرکت محفوظ کریں' : 'Save Movement',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(
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
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: yinMnBlue,
            ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : lavender.withValues(alpha: 0.3),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            LanguageController.isUrdu ? 'پروڈکٹ کی تفصیلات' : 'Product Details',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              color: isDark ? Colors.white : oxfordBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              color: isDark ? spaceCadet : Colors.white,
              onSelected: (val) async {
                final userId =
                    Supabase.instance.client.auth.currentUser?.id ?? '';
                final repo = ref.read(inventoryRepoProvider);

                if (val == 'duplicate') {
                  await repo.duplicateProduct(productId, userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageController.isUrdu ? 'پروڈکٹ کامیابی کے ساتھ کاپی ہو گیا!' : 'Product copied successfully!',
                          textDirection: LanguageController.contentTextDirection,
                        ),
                      ),
                    );
                    context.pop(true);
                  }
                } else if (val == 'delete') {
                  await repo.deleteProduct(productId);
                  if (context.mounted) context.pop(true);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(Icons.copy, color: isDark ? jordyBlue : yinMnBlue),
                      const SizedBox(width: 8),
                      Text(
                        LanguageController.isUrdu ? 'پروڈکٹ کی نقل بنائیں' : 'Duplicate Product',
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      const Icon(Icons.delete, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        LanguageController.isUrdu ? 'پروڈکٹ حذف کریں' : 'Delete Product',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
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
              return Center(
                child: Text(
                  LanguageController.isUrdu ? 'پروڈکٹ نہیں ملا۔' : 'Product not found.',
                  textDirection: LanguageController.contentTextDirection,
                ),
              );
            }

            return RefreshIndicator(
              color: yinMnBlue,
              onRefresh: () async => _refresh(ref),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    // Title Header Card
                    Card(
                      elevation: 0,
                      color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              textDirection: LanguageController.contentTextDirection,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : oxfordBlue,
                                    ),
                                  ),
                                ),
                                StockBadge(product: product),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SKU: ${product.sku ?? "N/A"} • Barcode: ${product.barcode ?? "N/A"}',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? lavender.withValues(alpha: 0.7) : spaceCadet.withValues(alpha: 0.6),
                              ),
                            ),
                            if (product.description != null &&
                                product.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                product.description!,
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? lavender : spaceCadet,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stock & Price Summary Grid
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: InventorySummaryCard(
                            title: LanguageController.isUrdu ? 'موجودہ اسٹاک' : 'Current Stock',
                            value:
                                '${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                            icon: Icons.inventory_outlined,
                            color: isDark ? jordyBlue : yinMnBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InventorySummaryCard(
                            title: LanguageController.isUrdu ? 'فروخت کی قیمت' : 'Selling Price',
                            value:
                                'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
                            icon: Icons.sell_outlined,
                            color: isDark ? jordyBlue : yinMnBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: InventorySummaryCard(
                            title: LanguageController.isUrdu ? 'خریداری کی قیمت' : 'Purchase Price',
                            value:
                                'Rs. ${product.purchasePrice.toStringAsFixed(2)}',
                            icon: Icons.shopping_bag_outlined,
                            color: isDark ? jordyBlue : yinMnBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InventorySummaryCard(
                            title: LanguageController.isUrdu ? 'کل اسٹاک ویلیو' : 'Total Stock Value',
                            value:
                                'Rs. ${product.totalStockValue.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet_outlined,
                            color: isDark ? jordyBlue : yinMnBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stock Actions Buttons Grid
                    Text(
                      LanguageController.isUrdu ? 'فوری اسٹاک ایڈجسٹمنٹ' : 'Quick Stock Adjustments',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? jordyBlue : oxfordBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
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
                            label: Text(
                              LanguageController.isUrdu ? 'اسٹاک ان' : 'Stock In',
                              textDirection: LanguageController.contentTextDirection,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
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
                            label: Text(
                              LanguageController.isUrdu ? 'اسٹاک آؤٹ' : 'Stock Out',
                              textDirection: LanguageController.contentTextDirection,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark ? jordyBlue.withValues(alpha: 0.4) : lavender,
                              ),
                            ),
                            onPressed: () => _showMovementModal(
                              context,
                              ref,
                              product,
                              StockMovementType.adjustment,
                            ),
                            icon: Icon(Icons.tune, color: isDark ? jordyBlue : yinMnBlue),
                            label: Text(
                              LanguageController.isUrdu ? 'ایڈجسٹ' : 'Adjust',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark ? jordyBlue.withValues(alpha: 0.4) : lavender,
                              ),
                            ),
                            onPressed: () => _showMovementModal(
                              context,
                              ref,
                              product,
                              StockMovementType.returnStock,
                            ),
                            icon: Icon(Icons.replay, color: isDark ? jordyBlue : yinMnBlue),
                            label: Text(
                              LanguageController.isUrdu ? 'واپسی' : 'Return',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stock Movements History
                    Text(
                      LanguageController.isUrdu ? 'اسٹاک سرگرمی کی ہسٹری' : 'Stock Activity History',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? jordyBlue : oxfordBlue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ref.watch(productMovementsProvider(productId)).when(
                          data: (movements) {
                            if (movements.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  LanguageController.isUrdu ? 'ابھی تک کوئی اسٹاک تبدیلی درج نہیں کی گئی۔' : 'No stock changes recorded yet.',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: TextStyle(
                                    color: isDark ? lavender.withValues(alpha: 0.6) : spaceCadet.withValues(alpha: 0.6),
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
                                color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
                              ),
                              itemBuilder: (context, index) {
                                return MovementTile(
                                  movement: movements[index],
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator(color: yinMnBlue)),
                          error: (e, _) => Text(
                            '${l10n.error}: $e',
                            textDirection: LanguageController.contentTextDirection,
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: yinMnBlue)),
          error: (e, _) => Center(
            child: Text(
              '${l10n.error}: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
        ),
      ),
    );
  }
}