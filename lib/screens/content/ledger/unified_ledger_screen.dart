import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';
import 'package:digital_khata/services/supplier_service.dart';

abstract class PartyLedgerEntry {
  DateTime get date;
  String get partyName;
  double get amount;
  String get type;
  String? get description;
}

class CustomerLedgerEntry implements PartyLedgerEntry {
  final String name;
  final Map<String, dynamic> transaction;

  CustomerLedgerEntry({
    required this.name,
    required this.transaction,
  });

  @override
  DateTime get date =>
      transaction['date'] is DateTime ? transaction['date'] : DateTime.now();

  @override
  String get partyName => name;

  @override
  double get amount => (transaction['amount'] as num?)?.toDouble() ?? 0.0;

  @override
  String get type =>
      'customer_${(transaction['type'] ?? 'GIVEN').toString().toLowerCase()}';

  @override
  String? get description => transaction['title'] as String?;
}

class SupplierLedgerEntry implements PartyLedgerEntry {
  final Supplier supplier;
  final SupplierTransaction transaction;

  SupplierLedgerEntry({
    required this.supplier,
    required this.transaction,
  });

  @override
  DateTime get date => transaction.createdAt;

  @override
  String get partyName => supplier.name;

  @override
  double get amount => transaction.amount;

  @override
  String get type =>
      'supplier_${transaction.type == SupplierTransactionType.given ? 'given' : 'received'}';

  @override
  String? get description => transaction.description;
}

final unifiedLedgerProvider =
    FutureProvider.family<List<PartyLedgerEntry>, String>(
  (ref, userId) async {
    final supabase = Supabase.instance.client;
    final supplierRepo = SupplierRepository(supabase);

    List<PartyLedgerEntry> entries = [];

    try {
      // 1. Fetch customers and their timeline entries
      final customersRes = await supabase
          .from('customers')
          .select('id, name')
          .eq('created_by', userId);

      final customersList = customersRes as List<dynamic>;

      for (var c in customersList) {
        final custId = c['id'] as String;
        final custName = c['name'] ?? 'Customer';

        final timeline = await CustomerService.getCustomerTimeline(custId);
        for (var tx in timeline) {
          entries.add(CustomerLedgerEntry(
            name: custName,
            transaction: tx,
          ));
        }
      }

      // 2. Fetch suppliers and their transactions
      final suppliers = await supplierRepo.getSuppliers(userId);
      for (var supplier in suppliers) {
        final transactions =
            await supplierRepo.getSupplierTransactions(supplier.id);
        for (var transaction in transactions) {
          entries.add(SupplierLedgerEntry(
            supplier: supplier,
            transaction: transaction,
          ));
        }
      }

      // Sort by date descending
      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries;
    } catch (e) {
      print('Error fetching unified ledger: $e');
      return [];
    }
  },
);

class UnifiedLedgerScreen extends ConsumerWidget {
  const UnifiedLedgerScreen({Key? key}) : super(key: key);

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(unifiedLedgerProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ledger),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref, userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : ref.watch(unifiedLedgerProvider(userId)).when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTransactions,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group entries by date
                  Map<String, List<PartyLedgerEntry>> groupedEntries = {};
                  for (var entry in entries) {
                    final dateKey =
                        DateFormat('MMM dd, yyyy').format(entry.date);
                    if (!groupedEntries.containsKey(dateKey)) {
                      groupedEntries[dateKey] = [];
                    }
                    groupedEntries[dateKey]!.add(entry);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(ref, userId),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedEntries.length,
                      itemBuilder: (context, index) {
                        final dateKey = groupedEntries.keys.elementAt(index);
                        final dayEntries = groupedEntries[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(
                                dateKey,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            // Entries for this date
                            ...dayEntries.map((entryTile) {
                              return _buildLedgerEntryTile(
                                context,
                                entryTile,
                                l10n,
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('${l10n.error}: $error'),
                ),
              ),
    );
  }

  Widget _buildLedgerEntryTile(
    BuildContext context,
    PartyLedgerEntry entry,
    AppLocalizations l10n,
  ) {
    IconData icon;
    Color color;
    String transactionType;

    if (entry.type.startsWith('customer_')) {
      final txType = entry.type.replaceFirst('customer_', '');
      if (txType == 'received' || txType == 'expense') {
        icon = Icons.arrow_downward;
        color = Colors.green;
        transactionType = l10n.received;
      } else {
        icon = Icons.arrow_upward;
        color = Colors.red;
        transactionType = l10n.given;
      }
    } else {
      final txType = entry.type.replaceFirst('supplier_', '');
      if (txType == 'given') {
        icon = Icons.arrow_upward;
        color = Colors.red;
        transactionType = l10n.given;
      } else {
        icon = Icons.arrow_downward;
        color = Colors.green;
        transactionType = l10n.received;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            entry.partyName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                entry.description ?? transactionType,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a').format(entry.date),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: Text(
            '${color == Colors.green ? '+' : '-'}Rs. ${entry.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}