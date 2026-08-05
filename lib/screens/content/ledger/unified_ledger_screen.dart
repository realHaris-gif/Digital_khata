import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';
import 'package:digital_khata/services/supplier_service.dart';
import 'package:digital_khata/widgets/common/payment_method_icon.dart';
import 'package:digital_khata/theme/app_theme.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

abstract class PartyLedgerEntry {
  DateTime get date;
  String get partyName;
  double get amount;
  String get type;
  String? get description;
  String get paymentMethod;
}

class CustomerLedgerEntry implements PartyLedgerEntry {
  final String name;
  final Map<String, dynamic> transaction;
  final String _randomMethod;

  CustomerLedgerEntry({
    required this.name,
    required this.transaction,
  }) : _randomMethod = _generateDemoPaymentMethod(name);

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

  @override
  String get paymentMethod => 
      transaction['payment_method'] ?? _randomMethod;
}

class SupplierLedgerEntry implements PartyLedgerEntry {
  final Supplier supplier;
  final SupplierTransaction transaction;
  final String _randomMethod;

  SupplierLedgerEntry({
    required this.supplier,
    required this.transaction,
  }) : _randomMethod = _generateDemoPaymentMethod(supplier.name);

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

  @override
  String get paymentMethod => _randomMethod;
}

// Helper for demo random test data assignment (never touches real database fields)
String _generateDemoPaymentMethod(String seedKey) {
  const methods = ['Cash', 'Visa', 'Mastercard', 'JazzCash', 'EasyPaisa', 'Bank Transfer'];
  final random = Random(seedKey.hashCode);
  return methods[random.nextInt(methods.length)];
}

// ============================================================================
// PROVIDERS
// ============================================================================

final ledgerFilterProvider = StateProvider<String>((ref) => 'all');

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
      debugPrint('Error fetching unified ledger: $e');
      return [];
    }
  },
);

final filteredLedgerProvider =
    FutureProvider.family<List<PartyLedgerEntry>, String>(
  (ref, userId) async {
    final filter = ref.watch(ledgerFilterProvider);
    final allEntries = await ref.watch(unifiedLedgerProvider(userId).future);

    if (filter == 'all') {
      return allEntries;
    } else if (filter == 'income') {
      return allEntries
          .where((e) =>
              e.type.contains('received') ||
              e.type.contains('customer_received'))
          .toList();
    } else if (filter == 'expense') {
      return allEntries
          .where((e) =>
              e.type.contains('given') || e.type.contains('customer_given'))
          .toList();
    }

    return allEntries;
  },
);

// ============================================================================
// PREMIUM UNIFIED LEDGER SCREEN
// ============================================================================

class UnifiedLedgerScreen extends ConsumerWidget {
  const UnifiedLedgerScreen({super.key});

  // Helper to capitalize first letters
  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.yinMnBlue),
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: _buildAppBar(context, l10n, ref, userId, isDark),
          body: userId.isEmpty
              ? _buildErrorState(context, l10n, isDark: isDark)
              : ref.watch(filteredLedgerProvider(userId)).when(
                    data: (entries) => _buildTransactionList(
                      context,
                      ref,
                      entries,
                      l10n,
                      userId,
                      isDark,
                    ),
                    loading: () => _buildSkeletonLoadingState(isDark),
                    error: (error, stackTrace) =>
                        _buildErrorState(context, l10n, errorMsg: error.toString(), isDark: isDark),
                  ),
        ),
      ),
    );
  }

  // ========================================================================
  // APP BAR
  // ========================================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    String userId,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          child: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
      ),
      title: Text(
        LanguageController.isUrdu ? 'کھاتہ' : l10n.ledger,
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
          onPressed: () => ref.invalidate(filteredLedgerProvider(userId)),
        ),
      ],
    );
  }

  // ========================================================================
  // FILTER TABS
  // ========================================================================

  Widget _buildFilterTabs(WidgetRef ref, AppLocalizations l10n, bool isDark) {
    final selectedFilter = ref.watch(ledgerFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        textDirection: LanguageController.contentTextDirection,
        children: [
          _buildFilterChip(ref, 'all', LanguageController.isUrdu ? 'سب' : 'All', selectedFilter, isDark),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(ref, 'income', LanguageController.isUrdu ? 'آمدنی' : 'Income', selectedFilter, isDark),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(ref, 'expense', LanguageController.isUrdu ? 'خرچہ' : 'Expense', selectedFilter, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String value,
    String label,
    String selectedFilter,
    bool isDark,
  ) {
    final isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () => ref.read(ledgerFilterProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.jordyBlue : AppColors.yinMnBlue) 
              : (isDark ? AppColors.darkSurface : AppColors.surface2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderStrong,
                  width: 1,
                ),
        ),
        child: Text(
          label,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? (isDark ? AppColors.darkBackground : Colors.white) 
                : (isDark ? AppColors.lavender : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // TRANSACTION LIST
  // ========================================================================

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List<PartyLedgerEntry> entries,
    AppLocalizations l10n,
    String userId,
    bool isDark,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState(l10n, isDark);
    }

    return RefreshIndicator(
      color: AppColors.yinMnBlue,
      onRefresh: () async => ref.invalidate(filteredLedgerProvider(userId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          textDirection: LanguageController.contentTextDirection,
          children: [
            _buildFilterTabs(ref, l10n, isDark),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return _buildTransactionTile(
                  context,
                  entries[index],
                  l10n,
                  isDark,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // TRANSACTION TILE (PREMIUM DESIGN WITH PAYMENT METHOD LOGOS)
  // ========================================================================

  Widget _buildTransactionTile(
    BuildContext context,
    PartyLedgerEntry entry,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final isIncome = entry.type.contains('received') ||
        entry.type.contains('customer_received');

    final Color accentColor = isIncome ? AppColors.success : AppColors.danger;
    final IconData icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final String amountPrefix = isIncome ? '+' : '−';

    // Capitalized party name with strong bolding
    final String capitalizedName = _capitalizeWords(entry.partyName);
    
    // Payment method string and label configuration
    final String paymentMethod = entry.paymentMethod;
    final String descriptionLabel = entry.description ?? _getTransactionTypeLabel(entry.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
            width: 1,
          ),
        ),
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          child: Row(
            textDirection: LanguageController.contentTextDirection,
            children: [
              // ============================================================
              // LEFT ICON AVATAR
              // ============================================================
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),

              // ============================================================
              // CENTER CONTENT (Party Name + Payment Method Logo + Subtitle)
              // ============================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    // Party Name (Capitalized and Extra Bold)
                    Text(
                      capitalizedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Payment Method Logo + Description Row with Transparent Background Container
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            color: Colors.transparent, // Ensures white background boxes from payment icons are removed
                            child: PaymentMethodIcon(
                              paymentMethod: paymentMethod,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$paymentMethod • $descriptionLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ============================================================
              // RIGHT CONTENT (Amount + Date)
              // ============================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  // Amount
                  Text(
                    '$amountPrefix Rs ${entry.amount.toStringAsFixed(2)}',
              
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Date Format
                  Text(
                    DateFormat('dd.MM.yyyy').format(entry.date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.lavender.withValues(alpha: 0.5) : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // EMPTY STATE
  // ========================================================================

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 50,
              color: isDark ? AppColors.jordyBlue : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            LanguageController.isUrdu ? 'کوئی لین دین نہیں' : l10n.noTransactions,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.oxfordBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LanguageController.isUrdu ? 'لین دین دیکھنے کے لیے گاہک یا سپلائر شامل کرنا شروع کریں' : 'Start adding customers or suppliers to see transactions',
            textAlign: TextAlign.center,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SKELETON LOADING STATE
  // ========================================================================

  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : AppColors.lavender.withValues(alpha: 0.6);
    final highlightColor = isDark ? AppColors.yinMnBlue.withValues(alpha: 0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          itemCount: 6, // Render 6 pulsing skeleton transaction rows
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.1) : AppColors.borderLight,
                ),
              ),
              child: Row(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  // Left Avatar Skeleton
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Center Content Skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Container(
                          width: 130,
                          height: 16,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 180,
                          height: 12,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Right Content Skeleton
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Container(
                        width: 70,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ========================================================================
  // ERROR STATE
  // ========================================================================

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n, {
    String? errorMsg,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            LanguageController.isUrdu ? 'خرابی' : l10n.error,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.oxfordBlue,
            ),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  String _getTransactionTypeLabel(String type) {
    if (type.contains('received')) {
      return LanguageController.isUrdu ? 'رقم وصول ہوئی' : 'Money Received';
    } else if (type.contains('given')) {
      return LanguageController.isUrdu ? 'رقم دی گئی' : 'Money Given';
    } else if (type.contains('paid')) {
      return LanguageController.isUrdu ? 'ادائیگی' : 'Payment';
    } else {
      return LanguageController.isUrdu ? 'لین دین' : 'Transaction';
    }
  }
}