import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw Exception('User is not authenticated.');
    }
  }

  /// Add new expense with optional customer link
  Future<void> addExpense({
    required String category,
    required double amount,
    String? customerId,
    String? description,
    String? notes,
    DateTime? date,
  }) async {
    try {
      _checkAuth();

      final data = {
        'user_id': _userId,
        'customer_id': customerId,
        'category': category,
        'amount': amount,
        'description': description ?? '',
        'notes': notes ?? '',
        'date': (date ?? DateTime.now()).toIso8601String(),
      };

      await _client.from('expenses').insert(data);
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  /// Update an existing expense by ID
  Future<void> updateExpense(
    String expenseId, {
    String? category,
    double? amount,
    String? customerId,
    String? description,
    String? notes,
  }) async {
    try {
      _checkAuth();

      final updateData = <String, dynamic>{};

      if (category != null) updateData['category'] = category;
      if (amount != null) updateData['amount'] = amount;
      if (customerId != null) updateData['customer_id'] = customerId;
      if (description != null) updateData['description'] = description;
      if (notes != null) updateData['notes'] = notes;

      await _client
          .from('expenses')
          .update(updateData)
          .eq('id', expenseId)
          .eq('user_id', _userId!);
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  /// Get expenses for a specific customer
  Future<List<Map<String, dynamic>>> getCustomerExpenses(String customerId) async {
    try {
      _checkAuth();

      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', _userId!)
          .eq('customer_id', customerId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting customer expenses: $e');
      return [];
    }
  }

  /// Get all user expenses (general or customer linked)
  Future<List<Map<String, dynamic>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      _checkAuth();

      var query = _client.from('expenses').select().eq('user_id', _userId!);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting expenses: $e');
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      _checkAuth();

      await _client
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', _userId!);
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }
}