import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = '4280391411', // Default emerald green
    this.icon = 'category',
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'General',
      description: json['description'] as String?,
      color: json['color'] as String? ?? '4280391411',
      icon: json['icon'] as String? ?? 'category',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
        'created_at': createdAt.toIso8601String(),
      };

  Color getDisplayColor() {
    try {
      final value = int.tryParse(color);
      if (value != null) {
        return Color(value);
      }
      final cleanColor = color.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('ff$cleanColor', radix: 16));
      } else if (cleanColor.length == 8) {
        return Color(int.parse(cleanColor, radix: 16));
      }
    } catch (_) {
      return Colors.teal;
    }
    return Colors.teal;
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        color,
        icon,
        createdAt,
      ];
}