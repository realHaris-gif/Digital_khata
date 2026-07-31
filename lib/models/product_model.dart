import 'package:equatable/equatable.dart';
import 'package:digital_khata/models/category_model.dart';

class Product extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? description;
  final double purchasePrice;
  final double sellingPrice;
  final double currentStock;
  final double minimumStock;
  final String unit;
  final String? imageUrl;
  final DateTime createdAt;
  final Category? category;

  const Product({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    this.description,
    this.purchasePrice = 0.0,
    required this.sellingPrice,
    this.currentStock = 0.0,
    this.minimumStock = 0.0,
    this.unit = 'pcs',
    this.imageUrl,
    required this.createdAt,
    this.category,
  });

  bool get isLowStock => currentStock <= minimumStock && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  double get totalStockValue => currentStock * purchasePrice;
  double get totalRetailValue => currentStock * sellingPrice;
  double get profitMargin => sellingPrice - purchasePrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimum_stock'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'description': description,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'current_stock': currentStock,
        'minimum_stock': minimumStock,
        'unit': unit,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  Product copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    double? currentStock,
    double? minimumStock,
    String? unit,
    String? imageUrl,
    DateTime? createdAt,
    Category? category,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        name,
        sku,
        barcode,
        description,
        purchasePrice,
        sellingPrice,
        currentStock,
        minimumStock,
        unit,
        imageUrl,
        createdAt,
        category,
      ];
}