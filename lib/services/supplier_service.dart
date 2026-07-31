import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_model.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';

class SupplierRepository {
  final SupabaseClient _supabase;

  SupplierRepository(this._supabase);

  // Get all suppliers for current user
  Future<List<Supplier>> getSuppliers(String userId, {bool activeOnly = true}) async {
    try {
      var query = _supabase
          .from('suppliers')
          .select()
          .eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('name', ascending: true);
      
      return (response as List).map((s) => Supplier.fromJson(s)).toList();
    } catch (e) {
      print('Error fetching suppliers: $e');
      rethrow;
    }
  }

  // Get supplier by id
  Future<Supplier?> getSupplierById(String supplierId) async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .eq('id', supplierId)
          .single();

      return Supplier.fromJson(response);
    } catch (e) {
      print('Error fetching supplier: $e');
      return null;
    }
  }

  // Search suppliers
  Future<List<Supplier>> searchSuppliers(
    String userId,
    String query, {
    bool activeOnly = true,
  }) async {
    try {
      var q = _supabase
          .from('suppliers')
          .select()
          .eq('user_id', userId)
          .or('name.ilike.%$query%,phone.ilike.%$query%');

      if (activeOnly) {
        q = q.eq('is_active', true);
      }

      final response = await q.order('name', ascending: true);
      
      return (response as List).map((s) => Supplier.fromJson(s)).toList();
    } catch (e) {
      print('Error searching suppliers: $e');
      return [];
    }
  }

  // Create supplier
  Future<Supplier> createSupplier({
    required String userId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double openingBalance = 0,
  }) async {
    try {
      final response = await _supabase.from('suppliers').insert({
        'user_id': userId,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'opening_balance': openingBalance,
        'current_balance': openingBalance,
      }).select().single();

      return Supplier.fromJson(response);
    } catch (e) {
      print('Error creating supplier: $e');
      rethrow;
    }
  }

  // Update supplier
  Future<Supplier> updateSupplier(
    String supplierId, {
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? openingBalance,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (notes != null) updateData['notes'] = notes;
      if (openingBalance != null) updateData['opening_balance'] = openingBalance;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('suppliers')
          .update(updateData)
          .eq('id', supplierId)
          .select()
          .single();

      return Supplier.fromJson(response);
    } catch (e) {
      print('Error updating supplier: $e');
      rethrow;
    }
  }

  // Delete supplier (soft delete)
  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _supabase
          .from('suppliers')
          .update({'is_active': false})
          .eq('id', supplierId);
    } catch (e) {
      print('Error deleting supplier: $e');
      rethrow;
    }
  }

  // Add supplier transaction
  Future<SupplierTransaction> addTransaction({
    required String supplierId,
    required String userId,
    required SupplierTransactionType type,
    required double amount,
    String? description,
    String? notes,
    String? referenceId,
  }) async {
    try {
      final response = await _supabase
          .from('supplier_transactions')
          .insert({
            'supplier_id': supplierId,
            'user_id': userId,
            'type': type.value,
            'amount': amount,
            'description': description,
            'notes': notes,
            'reference_id': referenceId,
          })
          .select()
          .single();

      // Update supplier current balance
      final supplier = await getSupplierById(supplierId);
      if (supplier != null) {
        final newBalance = _calculateBalance(supplier, type, amount);
        await _supabase
            .from('suppliers')
            .update({'current_balance': newBalance})
            .eq('id', supplierId);
      }

      return SupplierTransaction.fromJson(response);
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Get supplier transactions
  Future<List<SupplierTransaction>> getSupplierTransactions(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('supplier_transactions')
          .select()
          .eq('supplier_id', supplierId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((t) => SupplierTransaction.fromJson(t))
          .toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Get supplier balance
  Future<double> getSupplierBalance(String supplierId) async {
    try {
      final supplier = await getSupplierById(supplierId);
      return supplier?.currentBalance ?? 0;
    } catch (e) {
      print('Error getting balance: $e');
      return 0;
    }
  }

  // Get total suppliers count
  Future<int> getSuppliersCount(String userId) async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error counting suppliers: $e');
      return 0;
    }
  }

  // Get total payable amount (sum of all supplier dues)
  Future<double> getTotalPayable(String userId) async {
    try {
      final suppliers = await getSuppliers(userId);
      double total = 0;

      for (var supplier in suppliers) {
        if (supplier.currentBalance > 0) {
          total += supplier.currentBalance;
        }
      }

      return total;
    } catch (e) {
      print('Error calculating total payable: $e');
      return 0;
    }
  }

  // Stream suppliers for realtime updates
  // Note: SupabaseStreamFilterBuilder only supports a single .eq() filter.
  // Additional filters (is_active) and sorting are applied client-side.
  Stream<List<Supplier>> streamSuppliers(String userId) {
    return _supabase
        .from('suppliers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) {
          final filtered = list
              .where((s) => s['is_active'] == true)
              .map((s) => Supplier.fromJson(s))
              .toList();
          filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return filtered;
        });
  }

  double _calculateBalance(
    Supplier supplier,
    SupplierTransactionType type,
    double amount,
  ) {
    switch (type) {
      case SupplierTransactionType.given:
        return supplier.currentBalance + amount;
      case SupplierTransactionType.received:
        return supplier.currentBalance - amount;
    }
  }
}