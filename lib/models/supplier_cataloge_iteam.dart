import 'package:equatable/equatable.dart';

class SupplierCatalogItem extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String name;
  final String? sku;
  final String? description;
  final double purchasePrice;
  final double sellingPrice;
  final String unit;
  final bool isActive;
  final DateTime createdAt;

  const SupplierCatalogItem({
    required this.id,
    required this.userId,
    required this.supplierId,
    required this.name,
    this.sku,
    this.description,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.unit,
    this.isActive = true,
    required this.createdAt,
  });

  factory SupplierCatalogItem.fromJson(Map<String, dynamic> json) {
    return SupplierCatalogItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      supplierId: json['supplier_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'supplier_id': supplierId,
        'name': name,
        'sku': sku,
        'description': description,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'unit': unit,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        supplierId,
        name,
        sku,
        description,
        purchasePrice,
        sellingPrice,
        unit,
        isActive,
        createdAt,
      ];
}