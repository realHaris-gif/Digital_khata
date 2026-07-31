import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/account_model.dart';
import 'package:digital_khata/services/account_service.dart';

final accountsProvider =
    FutureProvider.family<List<Account>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final repository = AccountRepository(supabase);
  return repository.getAccounts(userId);
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  void _refreshList(WidgetRef ref, String userId) {
    ref.invalidate(accountsProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshList(ref, userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : ref.watch(accountsProvider(userId)).when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noAccounts,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res =
                                  await context.push('/add-account');
                              if (res == true) {
                                _refreshList(ref, userId);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addAccount),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate totals accurately
                  double totalBalance = 0.0;
                  double cashBalance = 0.0;
                  double bankBalance = 0.0;

                  for (var account in accounts) {
                    totalBalance += account.currentBalance;
                    if (account.type == AccountType.cash) {
                      cashBalance += account.currentBalance;
                    } else if (account.type == AccountType.bank) {
                      bankBalance += account.currentBalance;
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refreshList(ref, userId),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Financial summary cards grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: l10n.totalBalance,
                                amount: totalBalance,
                                icon: Icons.account_balance_wallet,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: l10n.cash,
                                amount: cashBalance,
                                icon: Icons.payments,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: l10n.bank,
                                amount: bankBalance,
                                icon: Icons.account_balance,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: SizedBox(), // Clean layout balancer
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Accounts list section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.accounts,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${accounts.length}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Accounts list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return _buildAccountCard(
                              context,
                              account,
                              ref,
                              userId,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('${l10n.error}: $error'),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await context.push('/add-account');
          if (res == true) {
            _refreshList(ref, userId);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    WidgetRef ref,
    String userId,
  ) {
    final Color accountColor = account.getDisplayColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accountColor.withOpacity(0.12),
          child: Icon(
            account.type == AccountType.cash
                ? Icons.payments
                : Icons.account_balance,
            color: accountColor,
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          account.type.displayName,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        trailing: Text(
          'Rs. ${account.currentBalance.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: account.currentBalance >= 0 ? Colors.green : Colors.red,
          ),
        ),
        onTap: () async {
          await context.push('/account/${account.id}');
          _refreshList(ref, userId);
        },
      ),
    );
  }
}