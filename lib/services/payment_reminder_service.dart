import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/services/notification_service.dart';

class PaymentReminderService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  /// Fetches all customers who have a positive outstanding balance (totalDue > 0)
  /// and checks whether they are currently within the cooldown window.
  static Future<List<Map<String, dynamic>>> getCustomersWithOutstandingBalances({
    Duration cooldownWindow = const Duration(hours: 24),
  }) async {
    if (_userId == null) return [];

    try {
      // 1. Fetch all customers for the current user using 'created_by'
      final response = await _client
          .from('customers')
          .select()
          .eq('created_by', _userId!)
          .order('name', ascending: true);

      final customers = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> eligibleCustomers = [];

      final now = DateTime.now();

      for (var customer in customers) {
        final customerId = customer['id'].toString();
        
        // Compute financial totals using existing CustomerService logic
        final totals = await CustomerService.getCustomerTotals(customerId);
        final totalDue = totals['totalDue'] ?? 0.0;

        // Only include customers who actually owe money
        if (totalDue > 0) {
          // Check last reminder timestamp from payment_reminders to evaluate cooldown
          final lastReminderRes = await _client
              .from('payment_reminders')
              .select('sent_at')
              .eq('user_id', _userId!)
              .eq('customer_id', customerId)
              .order('sent_at', ascending: false)
              .maybeSingle();

          bool canSend = true;
          if (lastReminderRes != null && lastReminderRes['sent_at'] != null) {
            final sentAt = DateTime.tryParse(lastReminderRes['sent_at'].toString());
            if (sentAt != null) {
              final difference = now.difference(sentAt);
              if (difference < cooldownWindow) {
                canSend = false; // Still within cooldown period
              }
            }
          }

          eligibleCustomers.add({
            ...customer,
            'total_due': totalDue,
            'can_send_reminder': canSend,
          });
        }
      }

      return eligibleCustomers;
    } catch (e) {
      debugPrint('Error fetching outstanding balances for reminders: $e');
      return [];
    }
  }

  /// Sends a bulk or individual payment reminder, records it as received, 
  /// deposits it directly into your financial account, and reflects it in accounts.
  static Future<Map<String, dynamic>> sendBulkReminders({
    required List<Map<String, dynamic>> selectedCustomers,
    String channel = 'in_app',
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    int successCount = 0;
    int failedCount = 0;

    // 1. Fetch your user's primary/active account to deposit the incoming payment into
    String? targetAccountId;
    try {
      final accountsRes = await _client
          .from('accounts')
          .select('id')
          .eq('created_by', _userId!)
          .limit(1);
      
      if (accountsRes.isNotEmpty) {
        targetAccountId = accountsRes.first['id']?.toString();
      }
    } catch (e) {
      debugPrint('Warning: Could not fetch accounts for deposit: $e');
    }

    for (var customer in selectedCustomers) {
      try {
        final customerId = customer['id'].toString();
        final customerName = customer['name'] ?? 'Customer';
        final amountDue = (customer['total_due'] as num?)?.toDouble() ?? 0.0;

        // 2. Log to payment_reminders table for tracking and cooldown enforcement
        await _client.from('payment_reminders').insert({
          'user_id': _userId!,
          'customer_id': customerId,
          'amount_due': amountDue,
          'channel': channel,
          'status': 'sent',
          'sent_at': DateTime.now().toIso8601String(),
        });

        // 3. Automatically record the payment into transactions ledger as RECEIVED
        // attaching account_id if available so it updates your account balance directly
        final Map<String, dynamic> transactionData = {
          'created_by': _userId!,
          'customer_id': customerId,
          'type': 'RECEIVED',
          'amount': amountDue,
          'item': 'Payment Received (Auto via Reminder)',
          'time': DateTime.now().toIso8601String(),
        };

        if (targetAccountId != null) {
          transactionData['account_id'] = targetAccountId;
        }

        await _client.from('transactions').insert(transactionData);

        // 4. Trigger in-app notification popup passing the correct amountDue
        await NotificationService().notifyPaymentReceived(amountDue, customerName);
        
        // 5. Log notification record for the notification center
        await _client.from('notifications').insert({
          'user_id': _userId!,
          'title': 'Payment Received / Reminder Sent',
          'message': 'Received Rs. ${amountDue.toStringAsFixed(2)} from $customerName',
          'type': 'success',
          'category': 'customers',
          'icon': 'check',
          'action_route': '/customers',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        successCount++;
      } catch (e) {
        debugPrint('Failed to process reminder/payment for customer: $e');
        failedCount++;
      }
    }

    return {
      'successCount': successCount,
      'failedCount': failedCount,
    };
  }
}