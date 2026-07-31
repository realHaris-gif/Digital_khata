import 'package:equatable/equatable.dart';

enum AccountTransactionType {
  deposit,
  withdrawal,
  transferIn,
  transferOut;

  String get value {
    switch (this) {
      case AccountTransactionType.deposit:
        return 'deposit';
      case AccountTransactionType.withdrawal:
        return 'withdrawal';
      case AccountTransactionType.transferIn:
        return 'transfer_in';
      case AccountTransactionType.transferOut:
        return 'transfer_out';
    }
  }

  String get displayName {
    switch (this) {
      case AccountTransactionType.deposit:
        return 'Deposit';
      case AccountTransactionType.withdrawal:
        return 'Withdrawal';
      case AccountTransactionType.transferIn:
        return 'Transfer In';
      case AccountTransactionType.transferOut:
        return 'Transfer Out';
    }
  }

  static AccountTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'deposit':
        return AccountTransactionType.deposit;
      case 'withdrawal':
        return AccountTransactionType.withdrawal;
      case 'transfer_in':
        return AccountTransactionType.transferIn;
      case 'transfer_out':
        return AccountTransactionType.transferOut;
      default:
        return AccountTransactionType.deposit;
    }
  }
}

class AccountTransaction extends Equatable {
  final String id;
  final String accountId;
  final String userId;
  final AccountTransactionType type;
  final double amount;
  final String? description;
  final String? relatedAccountId;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountTransaction({
    required this.id,
    required this.accountId,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    this.relatedAccountId,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountTransaction.fromJson(Map<String, dynamic> json) {
    return AccountTransaction(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      userId: json['user_id'] as String,
      type: AccountTransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      relatedAccountId: json['related_account_id'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'user_id': userId,
        'type': type.value,
        'amount': amount,
        'description': description,
        'related_account_id': relatedAccountId,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  AccountTransaction copyWith({
    String? id,
    String? accountId,
    String? userId,
    AccountTransactionType? type,
    double? amount,
    String? description,
    String? relatedAccountId,
    String? referenceType,
    String? referenceId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      relatedAccountId: relatedAccountId ?? this.relatedAccountId,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        userId,
        type,
        amount,
        description,
        relatedAccountId,
        referenceType,
        referenceId,
        notes,
        createdAt,
        updatedAt,
      ];
}