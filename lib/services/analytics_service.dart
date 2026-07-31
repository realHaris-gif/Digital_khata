import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw Exception('User is not authenticated.');
    }
  }

  /// 1. Get overall customer analytics and receivable dues accurately
  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    try {
      _checkAuth();

      final customersFuture = _client
          .from('customers')
          .select('id, name, phone, unique_id, address')
          .eq('created_by', _userId!);

      final transactionsFuture = _client
          .from('transactions')
          .select('customer_id, type, amount')
          .eq('created_by', _userId!);

      final results = await Future.wait([customersFuture, transactionsFuture]);
      final customersList = results[0] as List<dynamic>;
      final transactionsList = results[1] as List<dynamic>;

      if (customersList.isEmpty) {
        return {
          'totalCustomers': 0,
          'totalDue': 0.0,
          'highestDue': 0.0,
          'lowestDue': 0.0,
          'averageDue': 0.0,
          'customers': <Map<String, dynamic>>[],
        };
      }

      final Map<String, double> customerDues = {};

      for (var tx in transactionsList) {
        final custId = tx['customer_id'] as String?;
        if (custId == null) continue;

        final type = (tx['type'] as String?)?.toUpperCase() ?? '';
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'GIVEN') {
          customerDues[custId] = (customerDues[custId] ?? 0.0) + amount;
        } else if (type == 'RECEIVED') {
          customerDues[custId] = (customerDues[custId] ?? 0.0) - amount;
        }
      }

      double totalDue = 0.0;
      double highestDue = 0.0;
      double lowestDue = double.infinity;

      final List<Map<String, dynamic>> customers = [];

      for (var c in customersList) {
        final custId = c['id'] as String;
        final due = customerDues[custId] ?? 0.0;

        totalDue += due;
        if (due > highestDue) highestDue = due;
        if (due < lowestDue) lowestDue = due;

        customers.add({
          'id': custId,
          'name': c['name'] ?? 'Unknown',
          'phone': c['phone'] ?? 'N/A',
          'address': c['address'] ?? 'N/A',
          'unique_id': c['unique_id'] ?? '',
          'due': due,
        });
      }

      customers.sort((a, b) => (b['due'] as double).compareTo(a['due'] as double));

      final int totalCustomers = customers.length;
      final double averageDue = totalCustomers > 0 ? totalDue / totalCustomers : 0.0;

      return {
        'totalCustomers': totalCustomers,
        'totalDue': totalDue,
        'highestDue': highestDue,
        'lowestDue': lowestDue == double.infinity ? 0.0 : lowestDue,
        'averageDue': averageDue,
        'customers': customers,
      };
    } catch (e) {
      print('Error in getCustomerAnalytics: $e');
      rethrow;
    }
  }

  /// 2. Get monthly transaction summary for the last 12 months
  Future<List<Map<String, dynamic>>> getMonthlySummary() async {
    try {
      _checkAuth();

      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);

      final response = await _client
          .from('transactions')
          .select('type, amount, time')
          .eq('created_by', _userId!)
          .gte('time', twelveMonthsAgo.toIso8601String());

      final List<dynamic> transactions = response as List<dynamic>;

      final DateFormat keyFormat = DateFormat('yyyy-MM');
      final DateFormat labelFormat = DateFormat('MMM yyyy');

      final Map<String, Map<String, dynamic>> monthlyMap = {};

      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final key = keyFormat.format(monthDate);
        monthlyMap[key] = {
          'month': labelFormat.format(monthDate),
          'due': 0.0,
          'received': 0.0,
          'net': 0.0,
          'date': monthDate,
        };
      }

      for (var tx in transactions) {
        final timeStr = tx['time'] as String?;
        if (timeStr == null) continue;

        final txDate = DateTime.tryParse(timeStr);
        if (txDate == null) continue;

        final key = keyFormat.format(txDate);
        if (monthlyMap.containsKey(key)) {
          final type = (tx['type'] as String?)?.toUpperCase() ?? '';
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

          if (type == 'GIVEN') {
            monthlyMap[key]!['due'] = (monthlyMap[key]!['due'] as double) + amount;
          } else if (type == 'RECEIVED') {
            monthlyMap[key]!['received'] = (monthlyMap[key]!['received'] as double) + amount;
          }
        }
      }

      final List<Map<String, dynamic>> result = [];
      monthlyMap.forEach((key, value) {
        final due = value['due'] as double;
        final received = value['received'] as double;
        value['net'] = due - received;
        result.add(value);
      });

      return result;
    } catch (e) {
      print('Error in getMonthlySummary: $e');
      rethrow;
    }
  }

  /// 3. Get overdue customers (> daysOverdue with positive due)
  Future<List<Map<String, dynamic>>> getOverdueCustomers({int daysOverdue = 30}) async {
    try {
      _checkAuth();

      final customersFuture = _client
          .from('customers')
          .select('id, name, phone, unique_id')
          .eq('created_by', _userId!);

      final transactionsFuture = _client
          .from('transactions')
          .select('customer_id, type, amount, time')
          .eq('created_by', _userId!);

      final results = await Future.wait([customersFuture, transactionsFuture]);
      final customersList = results[0] as List<dynamic>;
      final transactionsList = results[1] as List<dynamic>;

      final Map<String, double> customerDues = {};
      final Map<String, DateTime> lastTxTimes = {};

      for (var tx in transactionsList) {
        final custId = tx['customer_id'] as String?;
        if (custId == null) continue;

        final type = (tx['type'] as String?)?.toUpperCase() ?? '';
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'GIVEN') {
          customerDues[custId] = (customerDues[custId] ?? 0.0) + amount;
        } else if (type == 'RECEIVED') {
          customerDues[custId] = (customerDues[custId] ?? 0.0) - amount;
        }

        final timeStr = tx['time'] as String?;
        if (timeStr != null) {
          final txTime = DateTime.tryParse(timeStr);
          if (txTime != null) {
            if (!lastTxTimes.containsKey(custId) || txTime.isAfter(lastTxTimes[custId]!)) {
              lastTxTimes[custId] = txTime;
            }
          }
        }
      }

      final now = DateTime.now();
      final List<Map<String, dynamic>> overdueCustomers = [];

      for (var c in customersList) {
        final custId = c['id'] as String;
        final due = customerDues[custId] ?? 0.0;
        final lastTx = lastTxTimes[custId];

        if (due > 0 && lastTx != null) {
          final daysSince = now.difference(lastTx).inDays;
          if (daysSince > daysOverdue) {
            overdueCustomers.add({
              'id': custId,
              'name': c['name'] ?? 'Unknown',
              'phone': c['phone'] ?? 'N/A',
              'unique_id': c['unique_id'] ?? '',
              'due': due,
              'daysSinceLastTransaction': daysSince,
            });
          }
        }
      }

      overdueCustomers.sort((a, b) =>
          (b['daysSinceLastTransaction'] as int).compareTo(a['daysSinceLastTransaction'] as int));

      return overdueCustomers;
    } catch (e) {
      print('Error in getOverdueCustomers: $e');
      rethrow;
    }
  }

  /// 4. Top customers sorted by due
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    try {
      final analytics = await getCustomerAnalytics();
      final List<Map<String, dynamic>> customers =
          List<Map<String, dynamic>>.from(analytics['customers'] ?? []);

      return customers.take(limit).toList();
    } catch (e) {
      print('Error in getTopCustomers: $e');
      rethrow;
    }
  }

  /// 5. Payment status distribution
  Future<Map<String, int>> getPaymentStatusDistribution() async {
    try {
      final analytics = await getCustomerAnalytics();
      final List<Map<String, dynamic>> customers =
          List<Map<String, dynamic>>.from(analytics['customers'] ?? []);

      int clear = 0;
      int partial = 0;
      int highDue = 0;

      for (var c in customers) {
        final double due = (c['due'] as num).toDouble();
        if (due == 0) {
          clear++;
        } else if (due > 0 && due <= 5000) {
          partial++;
        } else if (due > 5000) {
          highDue++;
        }
      }

      return {
        'clear': clear,
        'partial': partial,
        'highDue': highDue,
      };
    } catch (e) {
      print('Error in getPaymentStatusDistribution: $e');
      rethrow;
    }
  }

  /// 6. Export data summary for a period
  Future<Map<String, dynamic>> getExportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final analytics = await getCustomerAnalytics();
      final monthly = await getMonthlySummary();
      final overdue = await getOverdueCustomers();
      final statusDist = await getPaymentStatusDistribution();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'periodStart': startDate.toIso8601String(),
        'periodEnd': endDate.toIso8601String(),
        'analytics': analytics,
        'monthlySummary': monthly,
        'overdueCustomers': overdue,
        'statusDistribution': statusDist,
      };
    } catch (e) {
      print('Error in getExportSummary: $e');
      rethrow;
    }
  }

  /// 7. Get customer creation growth trend
  Future<List<Map<String, dynamic>>> getCustomerGrowth() async {
    try {
      _checkAuth();

      final response = await _client
          .from('customers')
          .select('created_at')
          .eq('created_by', _userId!);

      final List<dynamic> customers = response as List<dynamic>;
      final List<Map<String, dynamic>> growthTrend = [];
      final Map<String, int> monthlyCount = {};

      for (var doc in customers) {
        final createdAtStr = doc['created_at'] as String?;
        if (createdAtStr != null) {
          final date = DateTime.tryParse(createdAtStr);
          if (date != null) {
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
          }
        }
      }

      monthlyCount.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key))
        ..forEach((entry) {
          growthTrend.add({
            'month': entry.key,
            'count': entry.value,
          });
        });

      return growthTrend;
    } catch (e) {
      print('Error in getCustomerGrowth: $e');
      rethrow;
    }
  }
}