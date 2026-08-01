import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/widgets/bill_book/create_invoice_fab.dart';
import 'package:digital_khata/widgets/bill_book/invoice_ticket_card.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final singleInvoiceProvider =
    FutureProvider.family<Invoice?, String>((ref, invoiceId) async {
  final repo = ref.watch(invoiceRepoProvider);
  return repo.getInvoiceById(invoiceId);
});

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({Key? key, required this.invoiceId})
      : super(key: key);

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final GlobalKey _ticketKey = GlobalKey();

  void _refresh() {
    ref.invalidate(singleInvoiceProvider(widget.invoiceId));
  }

  Future<void> _shareInvoiceTicketImage() async {
    try {
      final boundary = _ticketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/invoice_receipt.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is your receipt for transaction #${widget.invoiceId}.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share receipt image: $e')),
        );
      }
    }
  }

  void _showShareTicketDialog(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _ticketKey,
                child: InvoiceTicketCard(invoice: invoice),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shareInvoiceTicketImage();
                  },
                  icon: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Share Receipt Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionBottomSheet(
      BuildContext context, WidgetRef ref, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildModalButton(
                icon: Icons.confirmation_number_outlined,
                label: 'Share Receipt Card',
                onTap: () {
                  Navigator.pop(context);
                  _showShareTicketDialog(context, invoice);
                },
              ),
              const SizedBox(height: 8),
              _buildModalButton(
                icon: Icons.copy_outlined,
                label: 'Duplicate invoice',
                onTap: () async {
                  Navigator.pop(context);
                  final userId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  final repo = ref.read(invoiceRepoProvider);
                  await repo.duplicateInvoice(widget.invoiceId, userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice duplicated!')),
                    );
                    context.pop(true);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildModalButton(
                icon: Icons.add_card_rounded,
                label: 'Record payment',
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentModal(context, ref, invoice);
                },
              ),
              const SizedBox(height: 8),
              _buildModalButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete invoice',
                isDanger: true,
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(invoiceRepoProvider);
                  await repo.deleteInvoice(widget.invoiceId);
                  if (context.mounted) context.pop(true);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color:
                isDanger ? const Color(0xFFFDF2F2) : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDanger ? Colors.redAccent : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDanger ? Colors.redAccent : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPaymentModal(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
  ) async {
    final amountController = TextEditingController(
      text: invoice.remainingBalance.toStringAsFixed(2),
    );
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';
    String? selectedAccountId;
    final formKey = GlobalKey<FormState>();

    bool isSubmitting = false;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final accountsRes = await Supabase.instance.client
        .from('accounts')
        .select('id, name')
        .eq('user_id', userId);
    final accounts = List<Map<String, dynamic>>.from(accountsRes as List);

    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Payment Amount (Rs.) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter payment amount';
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid amount';
                          }
                          if (parsed > invoice.remainingBalance + 0.01) {
                            return 'Amount cannot exceed remaining balance (Rs. ${invoice.remainingBalance.toStringAsFixed(2)})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                          DropdownMenuItem(
                              value: 'JazzCash', child: Text('JazzCash')),
                          DropdownMenuItem(
                              value: 'EasyPaisa', child: Text('EasyPaisa')),
                          DropdownMenuItem(
                              value: 'Credit Card', child: Text('Credit Card')),
                          DropdownMenuItem(
                              value: 'Custom', child: Text('Custom')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (accounts.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: accounts.map((acc) {
                            return DropdownMenuItem<String>(
                              value: acc['id'] as String,
                              child: Text(acc['name'] as String),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() => selectedAccountId = val);
                          },
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Payment Notes (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final repo = ref.read(invoiceRepoProvider);

                                  await repo.recordPayment(
                                    invoiceId: invoice.id,
                                    userId: userId,
                                    accountId: selectedAccountId,
                                    amount: double.parse(
                                        amountController.text.trim()),
                                    paymentMethod: selectedMethod,
                                    paymentDate: DateTime.now(),
                                    notes: notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _refresh();
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment failed: $e'),
                                      ),
                                    );
                                  }
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoiceAsync = ref.watch(singleInvoiceProvider(widget.invoiceId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoice detail',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          invoiceAsync.when(
            data: (invoice) => invoice == null
                ? const SizedBox()
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.black),
                        onPressed: () =>
                            _showShareTicketDialog(context, invoice),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: Colors.black),
                        onPressed: () =>
                            _showActionBottomSheet(context, ref, invoice),
                      ),
                    ],
                  ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Stack(
        children: [
          invoiceAsync.when(
            data: (invoice) {
              if (invoice == null) {
                return const Center(child: Text('Invoice not found.'));
              }

              final formattedIssueDate =
                  DateFormat('MMM dd, yyyy').format(invoice.createdAt);
              final formattedDueDate = DateFormat('MMM dd, yyyy').format(
                invoice.createdAt.add(const Duration(days: 14)),
              );

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 120,
                  ),
                  child: Column(
                    children: [
                      // Top ID and Status Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.description_outlined,
                                  size: 20, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InvoiceStatusBadge(status: invoice.status),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.push(
                                  '/bill-book/create',
                                  extra: invoice),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.black),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Receipt Document Layout
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'INVOICE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.stop,
                                      color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildMetaRow(
                                'Invoice number', invoice.invoiceNumber),
                            _buildMetaRow('Issue date', formattedIssueDate),
                            _buildMetaRow('Due date', formattedDueDate),
                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Billed to',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        invoice.customerName ??
                                            'Walk-in Customer',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Digital Khata Store',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Line Items Table Header
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Items',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Amount',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Line Items Rows
                            ...invoice.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs. ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Financial Summary Breakup
                            _buildSummaryRow('Subtotal',
                                'Rs. ${invoice.subtotal.toStringAsFixed(2)}'),
                            if (invoice.discount > 0)
                              _buildSummaryRow('Discount',
                                  '- Rs. ${invoice.discount.toStringAsFixed(2)}',
                                  textColor: Colors.red),
                            if (invoice.tax > 0)
                              _buildSummaryRow('Tax',
                                  '+ Rs. ${invoice.tax.toStringAsFixed(2)}'),
                            if (invoice.shipping > 0)
                              _buildSummaryRow('Shipping',
                                  '+ Rs. ${invoice.shipping.toStringAsFixed(2)}'),

                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Rs. ${invoice.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow('Total Paid',
                                'Rs. ${invoice.totalPaid.toStringAsFixed(2)}',
                                textColor: Colors.green, isBold: true),
                            _buildSummaryRow('Remaining',
                                'Rs. ${invoice.remainingBalance.toStringAsFixed(2)}',
                                textColor: Colors.redAccent, isBold: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Activity Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (invoice.remainingBalance > 0 &&
                              invoice.status != InvoiceStatus.cancelled)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _showPaymentModal(context, ref, invoice),
                              icon: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Record Payment',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (invoice.payments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No payments recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...invoice.payments.map((p) => PaymentTile(payment: p)),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
          ),

          // Reusable Persistent Create Invoice Floating Button
          const CreateInvoiceFAB(),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}