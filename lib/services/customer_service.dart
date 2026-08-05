import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  static void _checkAuth() {
    if (_userId == null) {
      throw Exception('User is not authenticated.');
    }
  }

  /// Real-time stream of customers belonging to the current authenticated user
  static Stream<List<Map<String, dynamic>>> get customersStream {
    _checkAuth();
    return _client
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('created_by', _userId!)
        .order('created_at', ascending: false);
  }

  /// Instance wrapper for customers stream
  Stream<List<Map<String, dynamic>>> get stream => customersStream;

  /// Fetch all customers ordered alphabetically (Static)
  static Future<List<Map<String, dynamic>>> getCustomersAlphabetically() async {
    _checkAuth();
    final response = await _client
        .from('customers')
        .select('id, name, phone, unique_id')
        .eq('created_by', _userId!)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Instance wrapper for fetching customers alphabetically
  Future<List<Map<String, dynamic>>> getCustomersAlphabeticallyInstance() =>
      getCustomersAlphabetically();

  /// Find a customer by their unique ID (Static)
  static Future<Map<String, dynamic>?> findCustomerByUniqueId(String uniqueId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('unique_id', uniqueId.trim())
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error finding customer by unique ID: $e');
      rethrow;
    }
  }

  /// Find a customer by unique ID (Instance delegate)
  Future<Map<String, dynamic>?> findCustomerByUniqueIdInstance(String id) =>
      findCustomerByUniqueId(id);

  /// Add Customer with instant return and error handling (Static)
static Future<Map<String, dynamic>> addCustomer({
    required String name,
    required String phone,
    double openingBalance = 0.0,
    String address = '',
    String notes = '',
  }) async {
    try {
      _checkAuth();

      final String uniqueId =
          'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final response = await _client
          .from('customers')
          .insert({
            'name': name,
            'phone': phone,
            'unique_id': uniqueId,
            'created_by': _userId!,
            'user_id': _userId!, 
            'opening_balance': openingBalance,
            'address': address,
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }
  /// Update Customer Details (Static)
  static Future<void> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? notes,
  }) async {
    try {
      _checkAuth();
      await _client
          .from('customers')
          .update({
            'name': name,
            'phone': phone,
            if (address != null) 'address': address,
            if (notes != null) 'notes': notes,
          })
          .eq('id', customerId)
          .eq('created_by', _userId!);
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  /// Delete Customer (Static)
  static Future<void> deleteCustomer(String customerId) async {
    try {
      _checkAuth();
      await _client
          .from('customers')
          .delete()
          .eq('id', customerId)
          .eq('created_by', _userId!);
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  /// Get Customer Totals (Static)
  ///
  /// Outstanding balance formula:
  ///   totalDue = sum(GIVEN) - sum(RECEIVED)
  /// (Opening balance is fetched for reference but excluded from totalDue to avoid double-counting with invoices)
  static Future<Map<String, double>> getCustomerTotals(String customerId) async {
    try {
      double openingBalance = 0.0;
      try {
        final customerRes = await _client
            .from('customers')
            .select('opening_balance')
            .eq('id', customerId)
            .maybeSingle();
        openingBalance =
            (customerRes?['opening_balance'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        print('Warning: could not load opening_balance for $customerId: $e');
      }

      List<dynamic> transactions = const [];
      try {
        final txRes = await _client
            .from('transactions')
            .select('type, amount')
            .eq('customer_id', customerId);
        transactions = txRes as List<dynamic>;
      } catch (e) {
        print('Warning: could not load transactions for $customerId: $e');
      }

      List<dynamic> expenses = const [];
      try {
        final expRes = await _client
            .from('expenses')
            .select('amount')
            .eq('customer_id', customerId);
        expenses = expRes as List<dynamic>;
      } catch (e) {
        print('Warning: could not load expenses for $customerId: $e');
      }

      double totalGiven = 0.0;
      double totalReceived = 0.0;
      double totalExpenses = 0.0;

      for (var tx in transactions) {
        final type = (tx['type'] as String?)?.toUpperCase() ?? '';
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'GIVEN') {
          totalGiven += amount;
        } else if (type == 'RECEIVED') {
          totalReceived += amount;
        }
      }

      for (var exp in expenses) {
        totalExpenses += (exp['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Exclude opening_balance from totalDue calculation to prevent duplicate amounts
      final double totalDue = totalGiven - totalReceived;
      final double netBalance = totalDue + totalExpenses;

      return {
        'totalGiven': totalGiven,
        'totalReceived': totalReceived,
        'totalPaid': totalReceived,
        'totalExpenses': totalExpenses,
        'openingBalance': openingBalance,
        'totalDue': totalDue,
        'netDue': totalDue,
        'netBalance': netBalance,
      };
    } catch (e) {
      print('Error computing customer summary: $e');
      return {
        'totalGiven': 0.0,
        'totalReceived': 0.0,
        'totalPaid': 0.0,
        'totalExpenses': 0.0,
        'openingBalance': 0.0,
        'totalDue': 0.0,
        'netDue': 0.0,
        'netBalance': 0.0,
      };
    }
  }

  static Future<Map<String, double>> getCustomerSummary(String customerId) =>
      getCustomerTotals(customerId);

  static Future<List<Map<String, dynamic>>> getCustomerTimeline(String customerId) async {
    try {
      final transactionsFuture = _client
          .from('transactions')
          .select()
          .eq('customer_id', customerId);

      final expensesFuture = _client
          .from('expenses')
          .select()
          .eq('customer_id', customerId);

      final results = await Future.wait([transactionsFuture, expensesFuture]);
      final transactions = List<Map<String, dynamic>>.from(results[0]);
      final expenses = List<Map<String, dynamic>>.from(results[1]);

      final List<Map<String, dynamic>> timeline = [];

      for (var tx in transactions) {
        timeline.add({
          'id': tx['id'],
          'entryType': 'TRANSACTION',
          'type': tx['type'],
          'amount': (tx['amount'] as num?)?.toDouble() ?? 0.0,
          'title': tx['item'] ?? tx['description'] ?? tx['type'],
          'date': DateTime.tryParse(tx['time'] ?? '') ?? DateTime.now(),
        });
      }

      for (var exp in expenses) {
        timeline.add({
          'id': exp['id'],
          'entryType': 'EXPENSE',
          'type': 'EXPENSE',
          'category': exp['category'],
          'amount': (exp['amount'] as num?)?.toDouble() ?? 0.0,
          'title': exp['description'] != null &&
                  exp['description'].toString().isNotEmpty
              ? exp['description']
              : exp['category'],
          'notes': exp['notes'] ?? '',
          'date': DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now(),
        });
      }

      timeline.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return timeline;
    } catch (e) {
      print('Error fetching timeline: $e');
      return [];
    }
  }

  // ===========================================================================
  // INSTANCE DELEGATE METHODS
  // ===========================================================================

  Future<Map<String, dynamic>> addCustomerInstance({
    required String name,
    required String phone,
    double openingBalance = 0.0,
    String address = '',
    String notes = '',
  }) =>
      addCustomer(
        name: name,
        phone: phone,
        openingBalance: openingBalance,
        address: address,
        notes: notes,
      );

  Future<void> updateCustomerInstance({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? notes,
  }) =>
      updateCustomer(
        customerId: customerId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
      );

  Future<void> deleteCustomerInstance(String customerId) =>
      deleteCustomer(customerId);

  Future<Map<String, double>> getCustomerSummaryInstance(String customerId) =>
      getCustomerSummary(customerId);

  Future<Map<String, double>> getCustomerTotalsInstance(String customerId) =>
      getCustomerTotals(customerId);

  Future<List<Map<String, dynamic>>> getCustomerTimelineInstance(String customerId) =>
      getCustomerTimeline(customerId);
}