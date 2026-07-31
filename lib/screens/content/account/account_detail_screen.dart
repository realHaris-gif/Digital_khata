import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/models/account_model.dart';
import 'package:digital_khata/models/account_transaction_model.dart';
import 'package:digital_khata/services/account_service.dart';

final accountDetailProvider =
    FutureProvider.family<Account?, String>((ref, accountId) async {
  final supabase = Supabase.instance.client;
  final repository = AccountRepository(supabase);
  return repository.getAccountById(accountId);
});

final accountTransactionsProvider =
    FutureProvider.family<List<AccountTransaction>, String>((ref, accountId) async {
  final supabase = Supabase.instance.client;
  final repository = AccountRepository(supabase);
  return repository.getAccountTransactions(accountId);
});

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailScreen({
    Key? key,
    required this.accountId,
  }) : super(key: key);

  void _refreshData(WidgetRef ref) {
    ref.invalidate(accountDetailProvider(accountId));
    ref.invalidate(accountTransactionsProvider(accountId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(accountDetailProvider(accountId)).when(
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account Details')),
            body: const Center(child: Text('Account not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _refreshData(ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                          'Rs. ${account.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: account.currentBalance >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                'Opening Balance',
                                'Rs. ${account.openingBalance.toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoRow(
                                'Account Type',
                                account.type.displayName,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAddDepositDialog(context, account, ref);
                        },
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text('Deposit'),
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
                        onPressed: () {
                          _showWithdrawDialog(context, account, ref);
                        },
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Withdraw'),
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
                const SizedBox(height: 12),

                // Transfer button
                OutlinedButton.icon(
                  onPressed: () {
                    _showTransferDialog(context, account, ref);
                  },
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Transfer Funds'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Transactions list header
                const Text(
                  'Account History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTransactionsList(context, ref),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, WidgetRef ref) {
    return ref.watch(accountTransactionsProvider(accountId)).when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No transactions recorded yet.'),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
    AccountTransaction transaction,
  ) {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case AccountTransactionType.deposit:
      case AccountTransactionType.transferIn:
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
      case AccountTransactionType.withdrawal:
      case AccountTransactionType.transferOut:
        icon = Icons.arrow_upward;
        color = Colors.red;
        break;
    }

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
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.description != null && transaction.description!.isNotEmpty
              ? transaction.description!
              : transaction.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - hh:mm a')
              .format(transaction.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${color == Colors.green ? '+' : '-'}Rs. ${transaction.amount.toStringAsFixed(2)}',
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

  void _showAddDepositDialog(
    BuildContext context,
    Account account,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TransactionDialog(
        accountId: account.id,
        type: AccountTransactionType.deposit,
        onSuccess: () => _refreshData(ref),
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    Account account,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TransactionDialog(
        accountId: account.id,
        type: AccountTransactionType.withdrawal,
        onSuccess: () => _refreshData(ref),
      ),
    );
  }

  void _showTransferDialog(
    BuildContext context,
    Account account,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TransferDialog(
        fromAccountId: account.id,
        onSuccess: () => _refreshData(ref),
      ),
    );
  }
}

class _TransactionDialog extends ConsumerStatefulWidget {
  final String accountId;
  final AccountTransactionType type;
  final VoidCallback onSuccess;

  const _TransactionDialog({
    Key? key,
    required this.accountId,
    required this.type,
    required this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<_TransactionDialog> createState() =>
      _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<_TransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
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
      final repository = AccountRepository(supabase);
      final userId = supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('User is not authenticated.');
      }

      await repository.addTransaction(
        accountId: widget.accountId,
        userId: userId,
        type: widget.type,
        amount: parsedAmount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded successfully')),
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
      title: Text(widget.type.displayName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., ATM cash withdrawal',
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
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _TransferDialog extends ConsumerStatefulWidget {
  final String fromAccountId;
  final VoidCallback onSuccess;

  const _TransferDialog({
    Key? key,
    required this.fromAccountId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<_TransferDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String? _selectedToAccountId;
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

  Future<void> _transfer() async {
    final amountText = _amountController.text.trim();
    final double? parsedAmount = double.tryParse(amountText);

    if (_selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }

    if (amountText.isEmpty || parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final repository = AccountRepository(supabase);
      final userId = supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('User is not authenticated.');
      }

      await repository.transferBetweenAccounts(
        fromAccountId: widget.fromAccountId,
        toAccountId: _selectedToAccountId!,
        userId: userId,
        amount: parsedAmount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed successfully')),
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
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    return AlertDialog(
      title: const Text('Transfer Funds'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target account dropdown
            FutureBuilder<List<Account>>(
              future: AccountRepository(supabase).getAccounts(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final accounts = snapshot.data!
                    .where((a) => a.id != widget.fromAccountId)
                    .toList();

                if (accounts.isEmpty) {
                  return const Text(
                    'No other active accounts available to transfer funds to.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedToAccountId,
                  onChanged: (value) {
                    setState(() => _selectedToAccountId = value);
                  },
                  items: accounts
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'To Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Transfer to bank account',
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
          onPressed: _isLoading ? null : _transfer,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Execute Transfer'),
        ),
      ],
    );
  }
}