import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';
import 'package:digital_khata/services/supplier_service.dart';

final supplierDetailProvider =
    FutureProvider.family<Supplier?, String>((ref, supplierId) async {
  final supabase = Supabase.instance.client;
  final repository = SupplierRepository(supabase);
  return repository.getSupplierById(supplierId);
});

final supplierTransactionsProvider =
    FutureProvider.family<List<SupplierTransaction>, String>((ref, supplierId) async {
  final supabase = Supabase.instance.client;
  final repository = SupplierRepository(supabase);
  return repository.getSupplierTransactions(supplierId);
});

class SupplierDetailScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailScreen({
    Key? key,
    required this.supplierId,
  }) : super(key: key);

  void _refreshData(WidgetRef ref) {
    ref.invalidate(supplierDetailProvider(supplierId));
    ref.invalidate(supplierTransactionsProvider(supplierId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(supplierDetailProvider(supplierId)).when(
      data: (supplier) {
        if (supplier == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Supplier Details')),
            body: const Center(child: Text('Supplier not found')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(supplier.name),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshData(ref),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Ledger'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, supplier, ref),
                _buildLedgerTab(context, supplier, ref),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Supplier Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Supplier Details')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Supplier supplier,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${supplier.currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: supplier.currentBalance > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          'Opening Balance',
                          'Rs. ${supplier.openingBalance.toStringAsFixed(2)}',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          'Created On',
                          DateFormat('MMM dd, yyyy')
                              .format(supplier.createdAt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Supplier info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact & Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(supplier.phone!),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(child: Text(supplier.address!)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (supplier.notes != null && supplier.notes!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(child: Text(supplier.notes!)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_card),
                  label: const Text('Add Payment'),
                  onPressed: () {
                    _showAddTransactionDialog(context, supplier, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () async {
                    final res = await context.push('/edit-supplier/${supplier.id}');
                    if (res == true) {
                      _refreshData(ref);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(
    BuildContext context,
    Supplier supplier,
    WidgetRef ref,
  ) {
    return ref.watch(supplierTransactionsProvider(supplier.id)).when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No transactions recorded yet.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionTile(context, transaction);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    SupplierTransaction transaction,
  ) {
    final isGiven = transaction.type == SupplierTransactionType.given;
    final color = isGiven ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isGiven ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(
          transaction.description != null && transaction.description!.isNotEmpty
              ? transaction.description!
              : (isGiven ? 'Money Given' : 'Money Received'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - hh:mm a')
              .format(transaction.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isGiven ? '+' : '-'}Rs. ${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(
    BuildContext context,
    Supplier supplier,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AddTransactionDialog(
        supplierId: supplier.id,
        onSuccess: () => _refreshData(ref),
      ),
    );
  }
}

class _AddTransactionDialog extends ConsumerStatefulWidget {
  final String supplierId;
  final VoidCallback onSuccess;

  const _AddTransactionDialog({
    Key? key,
    required this.supplierId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<_AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<_AddTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  SupplierTransactionType _selectedType = SupplierTransactionType.received;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final amountText = _amountController.text.trim();
    final double? parsedAmount = double.tryParse(amountText);

    if (amountText.isEmpty || parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final repository = SupplierRepository(supabase);
      final userId = supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('User is not authenticated.');
      }

      await repository.addTransaction(
        supplierId: widget.supplierId,
        userId: userId,
        type: _selectedType,
        amount: parsedAmount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Supplier Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<SupplierTransactionType>(
                    value: SupplierTransactionType.given,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                    title: const Text('Given'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<SupplierTransactionType>(
                    value: SupplierTransactionType.received,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                    title: const Text('Received'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount field
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: 'Rs. ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Payment for order #123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addTransaction,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Transaction'),
        ),
      ],
    );
  }
}