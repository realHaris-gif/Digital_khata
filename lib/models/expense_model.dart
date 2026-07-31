class Expense {
  final String? id;
  final String? userId;
  final String? customerId;
  final String category;
  final double amount;
  final String description;
  final String notes;
  final DateTime date;

  Expense({
    this.id,
    this.userId,
    this.customerId,
    required this.category,
    required this.amount,
    this.description = '',
    this.notes = '',
    required this.date,
  });

  static String normalizeCategory(String rawCategory) {
    final cat = rawCategory.trim();
    if (cat.isEmpty) return 'General';
    final allowed = [
      'General',
      'Transport',
      'Packaging',
      'Rent',
      'Utilities',
      'Inventory',
      'Salaries',
      'Maintenance'
    ];
    for (var a in allowed) {
      if (a.toLowerCase() == cat.toLowerCase()) return a;
    }
    return cat;
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      customerId: json['customer_id'] as String?,
      category: normalizeCategory(json['category'] ?? 'General'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      notes: json['notes'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'customer_id': customerId,
      'category': normalizeCategory(category),
      'amount': amount,
      'description': description,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? category,
    double? amount,
    String? description,
    String? notes,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}