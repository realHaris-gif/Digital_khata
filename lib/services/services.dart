import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<void> addPerson(String name, String phone, String uniqueId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client.from('customers').insert({
      'name': name.trim(),
      'phone': phone.trim(),
      'unique_id': uniqueId,
      'created_by': _userId,
    });
  }

  Stream<List<Map<String, dynamic>>> get peopleStream {
    if (_userId == null) return const Stream.empty();

    return _client
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('created_by', _userId!)
        .order('created_at', ascending: false);
  }

  Future<void> addDueItem(String personId, String item, double price) async {
    await _client.from('transactions').insert({
  'customer_id': personId,
  'created_by': _userId,
  'type': 'GIVEN',
  'item': item,
  'amount': price,
  'time': DateTime.now().toIso8601String(),
});
  }

  Future<void> addPayment(String personId, double amount, String description) async {
  await _client.from('transactions').insert({
    'customer_id': personId,
    'created_by': _userId,
    'type': 'RECEIVED',
    'amount': amount,
    'description': description,
    'time': DateTime.now().toIso8601String(),
  });
}

  /// Real-time stream for due items (GIVEN)
  Stream<List<Map<String, dynamic>>> getDueItemsStream(String personId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('customer_id', personId)
        .order('time', ascending: false)
        .map((events) => events.where((item) => item['type'] == 'GIVEN').toList());
  }

  /// Real-time stream for payments (RECEIVED)
  Stream<List<Map<String, dynamic>>> getPaymentsStream(String personId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('customer_id', personId)
        .order('time', ascending: false)
        .map((events) => events.where((item) => item['type'] == 'RECEIVED').toList());
  }

  Future<double> getTotalDue(String personId) async {
    try {
      final dueSnapshot = await _client
          .from('transactions')
          .select('amount')
          .eq('customer_id', personId)
          .eq('type', 'GIVEN');

      double totalDue = 0.0;
      for (var item in dueSnapshot) {
        final amount = item['amount'];
        if (amount != null) {
          totalDue += (amount as num).toDouble();
        }
      }

      final paymentSnapshot = await _client
          .from('transactions')
          .select('amount')
          .eq('customer_id', personId)
          .eq('type', 'RECEIVED');

      double totalPayments = 0.0;
      for (var payment in paymentSnapshot) {
        final amount = payment['amount'];
        if (amount != null) {
          totalPayments += (amount as num).toDouble();
        }
      }

      return totalDue - totalPayments;
    } catch (e) {
      print('Error calculating total due: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getAllPeopleWithTotals() async {
    if (_userId == null) return {};

    final response = await _client
        .from('customers')
        .select('id')
        .eq('created_by', _userId!);

    Map<String, double> totals = {};

    for (var person in response) {
      final personId = person['id'] as String;
      final total = await getTotalDue(personId);
      totals[personId] = total;
    }

    return totals;
  }
}

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}