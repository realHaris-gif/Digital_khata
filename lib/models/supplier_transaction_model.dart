import 'package:equatable/equatable.dart';

enum SupplierTransactionType {
  given,
  received;

  String get displayName {
    switch (this) {
      case SupplierTransactionType.given:
        return 'Given';
      case SupplierTransactionType.received:
        return 'Received';
    }
  }

  String get value {
    switch (this) {
      case SupplierTransactionType.given:
        return 'given';
      case SupplierTransactionType.received:
        return 'received';
    }
  }

  static SupplierTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'given':
        return SupplierTransactionType.given;
      case 'received':
        return SupplierTransactionType.received;
      default:
        return SupplierTransactionType.given;
    }
  }
}

class SupplierTransaction extends Equatable {
  final String id;
  final String supplierId;
  final String userId;
  final SupplierTransactionType type;
  final double amount;
  final String? description;
  final String? notes;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierTransaction({
    required this.id,
    required this.supplierId,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    this.notes,
    this.referenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierTransaction.fromJson(Map<String, dynamic> json) {
    return SupplierTransaction(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String,
      userId: json['user_id'] as String,
      type: SupplierTransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplier_id': supplierId,
        'user_id': userId,
        'type': type.value,
        'amount': amount,
        'description': description,
        'notes': notes,
        'reference_id': referenceId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SupplierTransaction copyWith({
    String? id,
    String? supplierId,
    String? userId,
    SupplierTransactionType? type,
    double? amount,
    String? description,
    String? notes,
    String? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierTransaction(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        userId,
        type,
        amount,
        description,
        notes,
        referenceId,
        createdAt,
        updatedAt,
      ];
}