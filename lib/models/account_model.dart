import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AccountType {
  cash,
  bank,
  easyPaisa,
  jazzCash,
  creditCard,
  other;

  // Lowercase aliases so legacy references work seamlessly
  static const AccountType easypaisa = AccountType.easyPaisa;
  static const AccountType jazzcash = AccountType.jazzCash;

  String get value {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.easyPaisa:
        return 'easypaisa';
      case AccountType.jazzCash:
        return 'jazzcash';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.easyPaisa:
        return 'EasyPaisa';
      case AccountType.jazzCash:
        return 'JazzCash';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.other:
        return 'Other';
    }
  }

  String get defaultIcon {
    switch (this) {
      case AccountType.cash:
        return 'currency_exchange';
      case AccountType.bank:
        return 'account_balance';
      case AccountType.easyPaisa:
      case AccountType.jazzCash:
        return 'phone_iphone';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.other:
        return 'wallet';
    }
  }

  Color get defaultColor {
    switch (this) {
      case AccountType.cash:
        return Colors.green;
      case AccountType.bank:
        return Colors.blue;
      case AccountType.easyPaisa:
        return Colors.lightGreen;
      case AccountType.jazzCash:
        return Colors.orange;
      case AccountType.creditCard:
        return Colors.purple;
      case AccountType.other:
        return Colors.grey;
    }
  }

  static AccountType fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'easypaisa':
        return AccountType.easyPaisa;
      case 'jazzcash':
        return AccountType.jazzCash;
      case 'creditcard':
        return AccountType.creditCard;
      case 'other':
        return AccountType.other;
      default:
        return AccountType.other;
    }
  }
}

class Account extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double openingBalance;
  final double currentBalance;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final type = AccountType.fromString(json['type'] as String? ?? 'cash');
    return Account(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['created_by'] as String? ?? '',
      name: json['name'] as String? ?? 'Account',
      type: type,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? type.defaultIcon,
      color: json['color'] as String? ??
          type.defaultColor.value.toRadixString(16),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type.value,
        'opening_balance': openingBalance,
        'current_balance': currentBalance,
        'icon': icon,
        'color': color,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Color getDisplayColor() {
    if (color != null && color!.isNotEmpty) {
      try {
        final cleanColor = color!.replaceAll('#', '');
        if (cleanColor.length == 6) {
          return Color(int.parse('ff$cleanColor', radix: 16));
        } else if (cleanColor.length == 8) {
          return Color(int.parse(cleanColor, radix: 16));
        }
      } catch (_) {
        return type.defaultColor;
      }
    }
    return type.defaultColor;
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? openingBalance,
    double? currentBalance,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        openingBalance,
        currentBalance,
        icon,
        color,
        isActive,
        createdAt,
        updatedAt,
      ];
}