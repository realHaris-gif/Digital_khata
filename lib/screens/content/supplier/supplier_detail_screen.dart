import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/models/supplier_transaction_model.dart';
import 'package:digital_khata/services/supplier_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

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

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  void _refreshData(WidgetRef ref) {
    ref.invalidate(supplierDetailProvider(supplierId));
    ref.invalidate(supplierTransactionsProvider(supplierId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: ref.watch(supplierDetailProvider(supplierId)).when(
        data: (supplier) {
          if (supplier == null) {
            return Scaffold(
              backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: isDark ? spaceCadet : Colors.white,
                elevation: 0,
                title: Text(
                  LanguageController.isUrdu ? 'سپلائر کی تفصیلات' : 'Supplier Details',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
                ),
              ),
              body: Center(
                child: Text(
                  LanguageController.isUrdu ? 'سپلائر نہیں ملا' : 'Supplier not found',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? lavender : Colors.grey),
                ),
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(
                  supplier.name,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: isDark ? spaceCadet : Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: isDark ? jordyBlue : oxfordBlue,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: isDark ? jordyBlue : yinMnBlue),
                    onPressed: () => _refreshData(ref),
                  ),
                ],
                bottom: TabBar(
                  indicatorColor: isDark ? jordyBlue : yinMnBlue,
                  labelColor: isDark ? jordyBlue : yinMnBlue,
                  unselectedLabelColor: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                  tabs: [
                    Tab(
                      child: Text(
                        LanguageController.isUrdu ? 'جائزہ' : 'Overview',
                        textDirection: LanguageController.contentTextDirection,
                      ),
                    ),
                    Tab(
                      child: Text(
                        LanguageController.isUrdu ? 'کھاتہ' : 'Ledger',
                        textDirection: LanguageController.contentTextDirection,
                      ),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildOverviewTab(context, supplier, ref, isDark),
                  _buildLedgerTab(context, supplier, ref, isDark),
                ],
              ),
            ),
          );
        },
        loading: () => Scaffold(
          backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? spaceCadet : Colors.white,
            title: Text(
              LanguageController.isUrdu ? 'سپلائر کی تفصیلات' : 'Supplier Details',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
            ),
          ),
          body: _buildSkeletonLoadingState(isDark),
        ),
        error: (error, stackTrace) => Scaffold(
          backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? spaceCadet : Colors.white,
            title: Text(
              LanguageController.isUrdu ? 'سپلائر کی تفصیلات' : 'Supplier Details',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
            ),
          ),
          body: Center(
            child: Text(
              LanguageController.isUrdu ? 'خرابی: $error' : 'Error: $error',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Supplier supplier,
    WidgetRef ref,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: LanguageController.contentTextDirection,
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  LanguageController.isUrdu ? 'موجودہ بیلنس' : 'Current Balance',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${supplier.currentBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: supplier.currentBalance > 0
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        LanguageController.isUrdu ? 'افتتاحی بیلنس' : 'Opening Balance',
                        'Rs. ${supplier.openingBalance.toStringAsFixed(2)}',
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        LanguageController.isUrdu ? 'تخلیق کی تاریخ' : 'Created On',
                        DateFormat('MMM dd, yyyy')
                            .format(supplier.createdAt),
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Supplier info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  LanguageController.isUrdu ? 'رابطہ اور تفصیلات' : 'Contact & Details',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                const SizedBox(height: 16),
                if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                  Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(Icons.phone_outlined, size: 20, color: isDark ? jordyBlue : yinMnBlue),
                      const SizedBox(width: 12),
                      Text(
                        supplier.phone!,
                        style: TextStyle(color: isDark ? lavender : Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: isDark ? jordyBlue : yinMnBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supplier.address!,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(color: isDark ? lavender : Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (supplier.notes != null && supplier.notes!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(Icons.note_outlined, size: 20, color: isDark ? jordyBlue : yinMnBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supplier.notes!,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(color: isDark ? lavender : Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick actions
          Row(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(
                    LanguageController.isUrdu ? 'ادائیگی شامل کریں' : 'Add Payment',
                    textDirection: LanguageController.contentTextDirection,
                  ),
                  onPressed: () {
                    _showAddTransactionDialog(context, supplier, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? jordyBlue : yinMnBlue,
                    foregroundColor: isDark ? oxfordBlue : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.edit_rounded, color: isDark ? jordyBlue : yinMnBlue),
                  label: Text(
                    LanguageController.isUrdu ? 'ترمیم' : 'Edit',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(color: isDark ? jordyBlue : yinMnBlue),
                  ),
                  onPressed: () async {
                    final res = await context.push('/edit-supplier/${supplier.id}');
                    if (res == true) {
                      _refreshData(ref);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? jordyBlue.withOpacity(0.4) : yinMnBlue),
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
    bool isDark,
  ) {
    return ref.watch(supplierTransactionsProvider(supplier.id)).when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  LanguageController.isUrdu ? 'ابھی تک کوئی لین دین درج نہیں کیا گیا۔' : 'No transactions recorded yet.',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionTile(context, transaction, isDark);
          },
        );
      },
      loading: () => _buildSkeletonLoadingState(isDark),
      error: (error, stackTrace) => Center(
        child: Text(
          LanguageController.isUrdu ? 'خرابی: $error' : 'Error: $error',
          textDirection: LanguageController.contentTextDirection,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    SupplierTransaction transaction,
    bool isDark,
  ) {
    final isGiven = transaction.type == SupplierTransactionType.given;
    final color = isGiven ? Colors.red.shade600 : Colors.green.shade600;

    final defaultDescription = isGiven 
        ? (LanguageController.isUrdu ? 'رقم دی گئی' : 'Money Given') 
        : (LanguageController.isUrdu ? 'رقم وصول ہوئی' : 'Money Received');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          transaction.description != null && transaction.description!.isNotEmpty
              ? transaction.description!
              : defaultDescription,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a')
              .format(transaction.createdAt),
          style: TextStyle(fontSize: 12, color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600),
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

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: LanguageController.contentTextDirection,
      children: [
        Text(
          label,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : oxfordBlue,
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

  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
            ],
          ),
        );
      },
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
        SnackBar(
          content: Text(
            LanguageController.isUrdu ? 'براہ کرم درست رقم درج کریں' : 'Please enter a valid amount',
            textDirection: LanguageController.contentTextDirection,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final repository = SupplierRepository(supabase);
      final userId = supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception(LanguageController.isUrdu ? 'صارف تصدیق شدہ نہیں ہے۔' : 'User is not authenticated.');
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
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'لین دین کامیابی کے ساتھ شامل کر لیا گیا' : 'Transaction added successfully',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'خرابی: $e' : 'Error: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
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
    final isDark = ThemeController.isDarkMode;

    return AlertDialog(
      backgroundColor: isDark ? SupplierDetailScreen.spaceCadet : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        LanguageController.isUrdu ? 'سپلائر کا لین دین شامل کریں' : 'Add Supplier Transaction',
        textDirection: LanguageController.contentTextDirection,
        style: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          textDirection: LanguageController.contentTextDirection,
          children: [
            // Type selection
            Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Expanded(
                  child: RadioListTile<SupplierTransactionType>(
                    value: SupplierTransactionType.given,
                    groupValue: _selectedType,
                    activeColor: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                    title: Text(
                      LanguageController.isUrdu ? 'دی گئی' : 'Given',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<SupplierTransactionType>(
                    value: SupplierTransactionType.received,
                    groupValue: _selectedType,
                    activeColor: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                    title: Text(
                      LanguageController.isUrdu ? 'وصول ہوئی' : 'Received',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue),
                    ),
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
              style: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue),
              decoration: InputDecoration(
                labelText: LanguageController.isUrdu ? 'رقم' : 'Amount',
                hintText: '0.00',
                labelStyle: TextStyle(color: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue),
                hintStyle: TextStyle(color: isDark ? SupplierDetailScreen.lavender.withOpacity(0.4) : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? SupplierDetailScreen.oxfordBlue.withOpacity(0.5) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue, width: 1.5),
                ),
                prefixText: 'Rs. ',
                prefixStyle: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue, fontWeight: FontWeight.bold),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(color: isDark ? Colors.white : SupplierDetailScreen.oxfordBlue),
              decoration: InputDecoration(
                labelText: LanguageController.isUrdu ? 'تفصیل (اختیاری)' : 'Description (Optional)',
                hintText: LanguageController.isUrdu ? 'مثال کے طور پر، آرڈر #123 کی ادائیگی' : 'e.g., Payment for order #123',
                labelStyle: TextStyle(color: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue),
                hintStyle: TextStyle(color: isDark ? SupplierDetailScreen.lavender.withOpacity(0.4) : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? SupplierDetailScreen.oxfordBlue.withOpacity(0.5) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? SupplierDetailScreen.lavender : Colors.grey.shade700),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? SupplierDetailScreen.jordyBlue : SupplierDetailScreen.yinMnBlue,
            foregroundColor: isDark ? SupplierDetailScreen.oxfordBlue : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isLoading ? null : _addTransaction,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  LanguageController.isUrdu ? 'لین دین شامل کریں' : 'Add Transaction',
                  textDirection: LanguageController.contentTextDirection,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}