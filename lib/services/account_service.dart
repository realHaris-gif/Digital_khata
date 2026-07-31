import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';
import '../models/account_transaction_model.dart';

class AccountRepository {
  final SupabaseClient _supabase;

  AccountRepository(this._supabase);

  // Get all accounts for user
  Future<List<Account>> getAccounts(String userId, {bool activeOnly = true}) async {
    try {
      var query = _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((a) => Account.fromJson(a)).toList();
    } catch (e) {
      print('Error fetching accounts: $e');
      rethrow;
    }
  }

  // Get account by id
  Future<Account?> getAccountById(String accountId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('id', accountId)
          .single();

      return Account.fromJson(response);
    } catch (e) {
      print('Error fetching account: $e');
      return null;
    }
  }

  // Create account
  Future<Account> createAccount({
    required String userId,
    required String name,
    required AccountType type,
    double openingBalance = 0,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _supabase
          .from('accounts')
          .insert({
            'user_id': userId,
            'name': name,
            'type': type.value,
            'opening_balance': openingBalance,
            'current_balance': openingBalance,
            'icon': icon ?? type.defaultIcon,
            'color': color ??
                type.defaultColor.toARGB32().toRadixString(16),
          })
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  // Update account
  Future<Account> updateAccount(
    String accountId, {
    String? name,
    AccountType? type,
    double? currentBalance,
    String? icon,
    String? color,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (type != null) updateData['type'] = type.value;
      if (currentBalance != null) updateData['current_balance'] = currentBalance;
      if (icon != null) updateData['icon'] = icon;
      if (color != null) updateData['color'] = color;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('accounts')
          .update(updateData)
          .eq('id', accountId)
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      print('Error updating account: $e');
      rethrow;
    }
  }

  // Delete account (soft delete)
  Future<void> deleteAccount(String accountId) async {
    try {
      await _supabase
          .from('accounts')
          .update({'is_active': false})
          .eq('id', accountId);
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Add account transaction
  Future<AccountTransaction> addTransaction({
    required String accountId,
    required String userId,
    required AccountTransactionType type,
    required double amount,
    String? description,
    String? relatedAccountId,
    String? referenceType,
    String? referenceId,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('account_transactions')
          .insert({
            'account_id': accountId,
            'user_id': userId,
            'type': type.value,
            'amount': amount,
            'description': description,
            'related_account_id': relatedAccountId,
            'reference_type': referenceType,
            'reference_id': referenceId,
            'notes': notes,
          })
          .select()
          .single();

      // Update account balance
      final account = await getAccountById(accountId);
      if (account != null) {
        final newBalance = _calculateBalance(account, type, amount);
        await _supabase
            .from('accounts')
            .update({'current_balance': newBalance})
            .eq('id', accountId);
      }

      return AccountTransaction.fromJson(response);
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Transfer between accounts
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      // Add withdrawal from source account
      await addTransaction(
        accountId: fromAccountId,
        userId: userId,
        type: AccountTransactionType.transferOut,
        amount: amount,
        description: description ?? 'Transfer to another account',
        relatedAccountId: toAccountId,
        referenceType: 'transfer',
      );

      // Add deposit to destination account
      await addTransaction(
        accountId: toAccountId,
        userId: userId,
        type: AccountTransactionType.transferIn,
        amount: amount,
        description: description ?? 'Transfer from another account',
        relatedAccountId: fromAccountId,
        referenceType: 'transfer',
      );
    } catch (e) {
      print('Error transferring between accounts: $e');
      rethrow;
    }
  }

  // Get account transactions
  Future<List<AccountTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('account_transactions')
          .select()
          .eq('account_id', accountId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((t) => AccountTransaction.fromJson(t))
          .toList();
    } catch (e) {
      print('Error fetching account transactions: $e');
      return [];
    }
  }

  // Get total cash balance (all cash-type accounts)
  Future<double> getTotalCashBalance(String userId) async {
    try {
      final accounts = await getAccounts(userId);
      double total = 0;

      for (var account in accounts) {
        if (account.type == AccountType.cash) {
          total += account.currentBalance;
        }
      }

      return total;
    } catch (e) {
      print('Error calculating cash balance: $e');
      return 0;
    }
  }

  // Get total bank balance (all bank-type accounts)
  Future<double> getTotalBankBalance(String userId) async {
    try {
      final accounts = await getAccounts(userId);
      double total = 0;

      for (var account in accounts) {
        if (account.type == AccountType.bank) {
          total += account.currentBalance;
        }
      }

      return total;
    } catch (e) {
      print('Error calculating bank balance: $e');
      return 0;
    }
  }

  // Get total balance across all accounts
  Future<double> getTotalBalance(String userId) async {
    try {
      final accounts = await getAccounts(userId);
      double total = 0;

      for (var account in accounts) {
        total += account.currentBalance;
      }

      return total;
    } catch (e) {
      print('Error calculating total balance: $e');
      return 0;
    }
  }

  // Stream accounts for realtime updates
  // Note: SupabaseStreamFilterBuilder only supports a single .eq() filter.
  // Additional filters (is_active) are applied client-side.
  Stream<List<Account>> streamAccounts(String userId) {
    return _supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final list = List<Map<String, dynamic>>.from(data)
              .where((a) => a['is_active'] == true)
              .toList();
          list.sort((a, b) {
            final dateA =
                DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                    DateTime.now();
            final dateB =
                DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                    DateTime.now();
            return dateB.compareTo(dateA);
          });
          return list.map((json) => Account.fromJson(json)).toList();
        });
  }

  double _calculateBalance(
    Account account,
    AccountTransactionType type,
    double amount,
  ) {
    switch (type) {
      case AccountTransactionType.deposit:
      case AccountTransactionType.transferIn:
        return account.currentBalance + amount;
      case AccountTransactionType.withdrawal:
      case AccountTransactionType.transferOut:
        return account.currentBalance - amount;
    }
  }
}