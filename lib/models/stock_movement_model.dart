import 'package:equatable/equatable.dart';

enum StockMovementType {
  inStock,
  outStock,
  adjustment,
  returnStock;

  String get value {
    switch (this) {
      case StockMovementType.inStock:
        return 'IN';
      case StockMovementType.outStock:
        return 'OUT';
      case StockMovementType.adjustment:
        return 'ADJUSTMENT';
      case StockMovementType.returnStock:
        return 'RETURN';
    }
  }

  String get displayName {
    switch (this) {
      case StockMovementType.inStock:
        return 'Stock In';
      case StockMovementType.outStock:
        return 'Stock Out';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.returnStock:
        return 'Return';
    }
  }

  static StockMovementType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'IN':
        return StockMovementType.inStock;
      case 'OUT':
        return StockMovementType.outStock;
      case 'ADJUSTMENT':
        return StockMovementType.adjustment;
      case 'RETURN':
        return StockMovementType.returnStock;
      default:
        return StockMovementType.inStock;
    }
  }
}

class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final StockMovementType type;
  final double quantity;
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.userId,
    required this.type,
    required this.quantity,
    this.reference,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: StockMovementType.fromString(json['type'] as String? ?? 'IN'),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'user_id': userId,
        'type': type.value,
        'quantity': quantity,
        'reference': reference,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        productId,
        userId,
        type,
        quantity,
        reference,
        notes,
        createdAt,
      ];
}