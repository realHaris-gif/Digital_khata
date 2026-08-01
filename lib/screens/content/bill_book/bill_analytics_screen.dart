import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final billAnalyticsProvider =
    FutureProvider.family<List<Invoice>, String>((ref, userId) async {
  final repo = ref.watch(invoiceRepoProvider);
  return repo.getInvoices(userId: userId, limit: 1000);
});

class BillAnalyticsScreen extends ConsumerWidget {
  const BillAnalyticsScreen({Key? key}) : super(key: key);

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(billAnalyticsProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Analytics'),
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
          : ref.watch(billAnalyticsProvider(userId)).when(
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return const Center(
                      child: Text(
                        'No invoice data available for analytics.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // 1. Overall Revenue & Average Invoice Value
                  final nonCancelled = invoices
                      .where((i) => i.status != InvoiceStatus.cancelled)
                      .toList();

                  final double totalSalesVolume = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.total);

                  final double totalRevenueCollected = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.totalPaid);

                  final double avgInvoiceValue = nonCancelled.isNotEmpty
                      ? totalSalesVolume / nonCancelled.length
                      : 0.0;

                  final double totalOutstanding = nonCancelled.fold(
                      0.0, (sum, inv) => sum + inv.remainingBalance);

                  // 2. Payment Method Distribution
                  final Map<String, double> methodTotals = {};
                  for (var inv in nonCancelled) {
                    for (var pay in inv.payments) {
                      methodTotals[pay.paymentMethod] =
                          (methodTotals[pay.paymentMethod] ?? 0.0) + pay.amount;
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(ref, userId),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // KPI Summary Cards Grid
                          Row(
                            children: [
                              Expanded(
                                child: InvoiceSummaryCard(
                                  title: 'Sales Volume',
                                  value: 'Rs. ${totalSalesVolume.toStringAsFixed(0)}',
                                  icon: Icons.show_chart,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InvoiceSummaryCard(
                                  title: 'Collected',
                                  value: 'Rs. ${totalRevenueCollected.toStringAsFixed(0)}',
                                  icon: Icons.payments_outlined,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: InvoiceSummaryCard(
                                  title: 'Outstanding Due',
                                  value: 'Rs. ${totalOutstanding.toStringAsFixed(0)}',
                                  icon: Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InvoiceSummaryCard(
                                  title: 'Avg Bill Value',
                                  value: 'Rs. ${avgInvoiceValue.toStringAsFixed(0)}',
                                  icon: Icons.calculate_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Payment Method Breakdown
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Method Breakdown',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  if (methodTotals.isEmpty)
                                    const Text(
                                      'No payments recorded yet.',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    ...methodTotals.entries.map((entry) {
                                      final double percentage =
                                          totalRevenueCollected > 0
                                              ? (entry.value /
                                                      totalRevenueCollected)
                                                  .clamp(0.0, 1.0)
                                              : 0.0;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  entry.key,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                Text(
                                                  'Rs. ${entry.value.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.teal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value: percentage,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color: Colors.teal,
                                              minHeight: 6,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              ),
    );
  }
}