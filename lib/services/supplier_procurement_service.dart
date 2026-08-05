import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_cataloge_iteam.dart';

class SupplierProcurementService {
  final SupabaseClient _supabase;

  SupplierProcurementService(this._supabase);

  // Fetch catalog items provided by a specific supplier
  Future<List<SupplierCatalogItem>> getSupplierCatalog(String supplierId) async {
    final response = await _supabase
        .from('supplier_catalog_items')
        .select()
        .eq('supplier_id', supplierId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List).map((json) => SupplierCatalogItem.fromJson(json)).toList();
  }

  // Add a new product to a supplier's catalog
  Future<SupplierCatalogItem> addSupplierCatalogItem({
    required String userId,
    required String supplierId,
    required String name,
    String? sku,
    String? description,
    required double purchasePrice,
    required double sellingPrice,
    String unit = 'pcs',
  }) async {
    final response = await _supabase
        .from('supplier_catalog_items')
        .insert({
          'user_id': userId,
          'supplier_id': supplierId,
          'name': name,
          'sku': sku,
          'description': description,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'unit': unit,
        })
        .select()
        .single();

    return SupplierCatalogItem.fromJson(response);
  }

  // Complete purchase order delivery: increases master inventory stock, logs movement, and updates invoice/status
  Future<void> deliverPurchaseOrder({
    required String userId,
    required String invoiceId,
    required String supplierId,
    required List<Map<String, dynamic>> orderedItems,
  }) async {
    // 1. Update Invoice status to Paid/Delivered
    await _supabase
        .from('invoices')
        .update({'status': 'Paid', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', invoiceId);

    // 2. Loop through ordered items and increase inventory stock automatically
    for (var item in orderedItems) {
      final productName = item['product_name'] as String;
      final quantity = (item['quantity'] as num).toDouble();
      final purchasePrice = (item['unit_price'] as num).toDouble();

      // Check if product exists in main inventory, otherwise create it
      final existingProduct = await _supabase
          .from('products')
          .select('id, current_stock')
          .eq('user_id', userId)
          .eq('name', productName)
          .maybeSingle();

      if (existingProduct != null) {
        final productId = existingProduct['id'] as String;
        final currentStock = (existingProduct['current_stock'] as num).toDouble();
        final newStock = currentStock + quantity;

        // Update product stock and purchase price
        await _supabase.from('products').update({
          'current_stock': newStock,
          'purchase_price': purchasePrice,
        }).eq('id', productId);

        // Record stock movement
        await _supabase.from('stock_movements').insert({
          'user_id': userId,
          'product_id': productId,
          'type': 'IN',
          'quantity': quantity,
          'reference': 'Purchase Order Delivery',
          'notes': 'Received from supplier',
        });
      } else {
        // Automatically onboard new supplier item into master inventory
        final newProdRes = await _supabase.from('products').insert({
          'user_id': userId,
          'name': productName,
          'purchase_price': purchasePrice,
          'selling_price': purchasePrice * 1.3,
          'current_stock': quantity,
          'unit': item['unit'] ?? 'pcs',
        }).select('id').single();

        final newProductId = newProdRes['id'] as String;

        await _supabase.from('stock_movements').insert({
          'user_id': userId,
          'product_id': newProductId,
          'type': 'IN',
          'quantity': quantity,
          'reference': 'Purchase Order Onboarding',
          'notes': 'New product onboarded from supplier catalog',
        });
      }
    }
  }
}