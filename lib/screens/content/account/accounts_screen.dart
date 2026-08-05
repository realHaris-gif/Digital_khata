import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/account_model.dart';
import 'package:digital_khata/services/account_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

final accountsProvider =
    FutureProvider.family<List<Account>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final repository = AccountRepository(supabase);
  return repository.getAccounts(userId);
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _refreshList(WidgetRef ref, String userId) {
    ref.invalidate(accountsProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            l10n.accounts,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.oxfordBlue,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 24, color: isDark ? AppColors.jordyBlue : AppColors.textSecondary),
              onPressed: () => _refreshList(ref, userId),
            ),
          ],
        ),
        body: userId.isEmpty
            ? Center(
                child: Text(
                  l10n.error,
                  textDirection: LanguageController.contentTextDirection,
                ),
              )
            : ref.watch(accountsProvider(userId)).when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance,
                                size: 64, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.noAccounts,
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.lavender : AppColors.spaceCadet,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.yinMnBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                              onPressed: () async {
                                final res =
                                    await context.push('/add-account');
                                if (res == true) {
                                  _refreshList(ref, userId);
                                }
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                l10n.addAccount,
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(color: Colors.white),
                              ),
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
                      color: AppColors.yinMnBlue,
                      onRefresh: () async => _refreshList(ref, userId),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          // Financial summary cards grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: l10n.totalBalance,
                                  amount: totalBalance,
                                  icon: Icons.account_balance_wallet,
                                  color: AppColors.yinMnBlue,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: l10n.cash,
                                  amount: cashBalance,
                                  icon: Icons.payments,
                                  color: AppColors.yinMnBlue,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: l10n.bank,
                                  amount: bankBalance,
                                  icon: Icons.account_balance,
                                  color: AppColors.yinMnBlue,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Expanded(
                                child: SizedBox(), // Clean layout balancer
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Accounts list section header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.accounts,
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                                ),
                              ),
                              Text(
                                '${accounts.length}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: isDark ? AppColors.lavender : AppColors.spaceCadet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

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
                                isDark,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${l10n.error}: $error',
                          textDirection: LanguageController.contentTextDirection,
                        ),
                      ],
                    ),
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.yinMnBlue,
          onPressed: () async {
            final res = await context.push('/add-account');
            if (res == true) {
              _refreshList(ref, userId);
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: isDark ? AppColors.jordyBlue : color, size: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.lavender : AppColors.spaceCadet,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
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
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.yinMnBlue.withValues(alpha: 0.15),
          child: Icon(
            account.type == AccountType.cash
                ? Icons.payments
                : Icons.account_balance,
            color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
          ),
        ),
        title: Text(
          account.name,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.oxfordBlue,
          ),
        ),
        subtitle: Text(
          account.type.displayName,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
          ),
        ),
        trailing: Text(
          'Rs. ${account.currentBalance.toStringAsFixed(2)}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: account.currentBalance >= 0 ? Colors.green.shade400 : Colors.red.shade400,
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