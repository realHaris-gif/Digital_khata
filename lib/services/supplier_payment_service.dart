import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';

class SupplierPaymentService {
  final SupabaseClient _supabase;

  SupplierPaymentService(this._supabase);

  /// Record a payment sent from your side to the supplier
  Future<void> paySupplier({
    required String userId,
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? referenceId,
    String? notes,
  }) async {
    // 1. Record the transaction as 'given' (money given/sent to supplier)
    await _supabase.from('supplier_transactions').insert({
      'supplier_id': supplierId,
      'user_id': userId,
      'type': SupplierTransactionType.given.value,
      'amount': amount,
      'description': 'Payment sent via $paymentMethod',
      'notes': notes,
      'reference_id': referenceId,
    });

    // 2. Fetch current supplier balance and subtract the paid amount
    final supplierRes = await _supabase
        .from('suppliers')
        .select('current_balance')
        .eq('id', supplierId)
        .single();

    final currentBalance = (supplierRes['current_balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = currentBalance - amount;

    // 3. Update supplier's current outstanding balance
    await _supabase
        .from('suppliers')
        .update({'current_balance': newBalance})
        .eq('id', supplierId);
  }
}