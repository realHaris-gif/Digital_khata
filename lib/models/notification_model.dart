import 'package:flutter/material.dart';

enum NotificationType { success, information, warning, error }

enum NotificationCategory {
  transactions,
  customers,
  invoices,
  inventory,
  expenses,
  suppliers,
  employees,
  reports,
  system,
  backup,
  security,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationCategory category;
  final IconData icon;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? actionRoute;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.icon,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
    this.actionRoute,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => NotificationType.information,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'] as String,
        orElse: () => NotificationCategory.system,
      ),
      icon: _getIconFromString(json['icon'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      actionRoute: json['action_route'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'category': category.name,
        'icon': _getStringFromIcon(icon),
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'metadata': metadata,
        'action_route': actionRoute,
      };

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationCategory? category,
    IconData? icon,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
    String? actionRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.information:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
    }
  }

  static IconData _getIconFromString(String? iconString) {
    if (iconString == null) return Icons.notifications_rounded;
    
    final iconMap = {
      'check_circle': Icons.check_circle_rounded,
      'info': Icons.info_rounded,
      'warning': Icons.warning_rounded,
      'error': Icons.error_rounded,
      'person_add': Icons.person_add_rounded,
      'person': Icons.person_rounded,
      'receipt': Icons.receipt_long_rounded,
      'inventory': Icons.inventory_2_rounded,
      'money': Icons.attach_money_rounded,
      'business': Icons.business_rounded,
      'group': Icons.group_rounded,
      'analytics': Icons.analytics_rounded,
      'backup': Icons.backup_rounded,
      'security': Icons.security_rounded,
      'sync': Icons.sync_rounded,
      'credit_card': Icons.credit_card_rounded,
      'payment': Icons.payment_rounded,
      'package': Icons.inventory_rounded, // Fixed non-existent package_rounded symbol fallback
      'trending_up': Icons.trending_up_rounded,
      'trending_down': Icons.trending_down_rounded,
    };
    
    return iconMap[iconString] ?? Icons.notifications_rounded;
  }

  static String _getStringFromIcon(IconData icon) {
    final iconMap = {
      Icons.check_circle_rounded: 'check_circle',
      Icons.info_rounded: 'info',
      Icons.warning_rounded: 'warning',
      Icons.error_rounded: 'error',
      Icons.person_add_rounded: 'person_add',
      Icons.person_rounded: 'person',
      Icons.receipt_long_rounded: 'receipt',
      Icons.inventory_2_rounded: 'inventory',
      Icons.attach_money_rounded: 'money',
      Icons.business_rounded: 'business',
      Icons.group_rounded: 'group',
      Icons.analytics_rounded: 'analytics',
      Icons.backup_rounded: 'backup',
      Icons.security_rounded: 'security',
      Icons.sync_rounded: 'sync',
      Icons.credit_card_rounded: 'credit_card',
      Icons.payment_rounded: 'payment',
      Icons.inventory_rounded: 'package',
      Icons.trending_up_rounded: 'trending_up',
      Icons.trending_down_rounded: 'trending_down',
    };
    
    return iconMap[icon] ?? 'info';
  }
}