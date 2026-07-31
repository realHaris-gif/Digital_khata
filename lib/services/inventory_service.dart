import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';

class InventoryRepository {
  final SupabaseClient _supabase;

  InventoryRepository(this._supabase);

  // =========================================================
  // CATEGORIES MANAGEMENT
  // =========================================================

  Future<List<Category>> getCategories(String userId) async {
    final response = await _supabase
        .from('categories')
        .select('*')
        .eq('user_id', userId)
        .order('name', ascending: true);

    return (response as List).map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory({
    required String userId,
    required String name,
    String? description,
    String color = '4280391411',
    String icon = 'category',
  }) async {
    final response = await _supabase
        .from('categories')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
        })
        .select()
        .single();

    return Category.fromJson(response);
  }

  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    required String color,
    required String icon,
  }) async {
    final response = await _supabase
        .from('categories')
        .update({
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
        })
        .eq('id', categoryId)
        .select()
        .single();

    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  // =========================================================
  // PRODUCTS MANAGEMENT
  // =========================================================

  Future<List<Product>> getProducts({
    required String userId,
    String? searchQuery,
    String? categoryId,
    bool? lowStockOnly,
    bool? outOfStockOnly,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('products')
        .select('*, categories(*)')
        .eq('user_id', userId);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    if (outOfStockOnly == true) {
      query = query.lte('current_stock', 0);
    } else if (lowStockOnly == true) {
      query = query.filter('current_stock', 'lte', 'minimum_stock');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('name.ilike.$term,sku.ilike.$term,barcode.ilike.$term');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProductById(String productId) async {
    final response = await _supabase
        .from('products')
        .select('*, categories(*)')
        .eq('id', productId)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  Future<Product> createProduct({
    required String userId,
    String? categoryId,
    required String name,
    String? sku,
    String? barcode,
    String? description,
    double purchasePrice = 0.0,
    required double sellingPrice,
    double initialStock = 0.0,
    double minimumStock = 0.0,
    String unit = 'pcs',
    String? imageUrl,
  }) async {
    final response = await _supabase
        .from('products')
        .insert({
          'user_id': userId,
          'category_id': categoryId,
          'name': name,
          'sku': sku,
          'barcode': barcode,
          'description': description,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'current_stock': initialStock,
          'minimum_stock': minimumStock,
          'unit': unit,
          'image_url': imageUrl,
        })
        .select('*, categories(*)')
        .single();

    final product = Product.fromJson(response);

    // Record initial stock movement if starting stock > 0
    if (initialStock > 0) {
      await recordStockMovement(
        userId: userId,
        productId: product.id,
        type: StockMovementType.inStock,
        quantity: initialStock,
        notes: 'Initial stock setup',
      );
    }

    return product;
  }

  Future<Product> updateProduct({
    required String productId,
    String? categoryId,
    required String name,
    String? sku,
    String? barcode,
    String? description,
    required double purchasePrice,
    required double sellingPrice,
    required double minimumStock,
    required String unit,
    String? imageUrl,
  }) async {
    final response = await _supabase
        .from('products')
        .update({
          'category_id': categoryId,
          'name': name,
          'sku': sku,
          'barcode': barcode,
          'description': description,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'minimum_stock': minimumStock,
          'unit': unit,
          'image_url': imageUrl,
        })
        .eq('id', productId)
        .select('*, categories(*)')
        .single();

    return Product.fromJson(response);
  }

  Future<Product> duplicateProduct(String productId, String userId) async {
    final original = await getProductById(productId);
    if (original == null) throw Exception('Original product not found');

    return createProduct(
      userId: userId,
      categoryId: original.categoryId,
      name: '${original.name} (Copy)',
      sku: original.sku != null ? '${original.sku}-COPY' : null,
      barcode: null, // Avoid duplicate barcode constraints
      description: original.description,
      purchasePrice: original.purchasePrice,
      sellingPrice: original.sellingPrice,
      initialStock: 0, // Reset initial stock for duplicate
      minimumStock: original.minimumStock,
      unit: original.unit,
      imageUrl: original.imageUrl,
    );
  }

  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  // =========================================================
  // STOCK MOVEMENTS
  // =========================================================

  Future<void> recordStockMovement({
    required String userId,
    required String productId,
    required StockMovementType type,
    required double quantity,
    String? reference,
    String? notes,
  }) async {
    await _supabase.from('stock_movements').insert({
      'user_id': userId,
      'product_id': productId,
      'type': type.value,
      'quantity': quantity,
      'reference': reference,
      'notes': notes,
    });
  }

  Future<List<StockMovement>> getProductMovements(String productId) async {
    final response = await _supabase
        .from('stock_movements')
        .select('*')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StockMovement.fromJson(json))
        .toList();
  }

  Future<List<StockMovement>> getRecentMovements(String userId,
      {int limit = 10}) async {
    final response = await _supabase
        .from('stock_movements')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => StockMovement.fromJson(json))
        .toList();
  }
}