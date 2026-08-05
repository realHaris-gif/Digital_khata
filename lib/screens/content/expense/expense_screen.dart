import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';
import '../../../services/expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'General';
  double _amount = 0.0;
  String _description = '';
  String _notes = '';
  bool _isSaving = false;

  final List<String> _defaultCategories = [
    'General',
    'Rent',
    'Utilities',
    'Inventory',
    'Salaries',
    'Transport',
    'Maintenance',
  ];

  void _showAddOrEditExpenseDialog({Map<String, dynamic>? existingExpense}) {
    final isEditing = existingExpense != null;
    final isDark = ThemeController.isDarkMode;

    if (isEditing) {
      _selectedCategory = existingExpense['category'] ?? 'General';
      _amount = (existingExpense['amount'] as num?)?.toDouble() ?? 0.0;
      _description = existingExpense['description'] ?? '';
      _notes = existingExpense['notes'] ?? '';
    } else {
      _selectedCategory = 'General';
      _amount = 0.0;
      _description = '';
      _notes = '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                        isEditing 
                            ? (LanguageController.isUrdu ? 'خرچے میں ترمیم کریں' : 'Edit Expense') 
                            : (LanguageController.isUrdu ? 'نیا خرچہ شامل کریں' : 'Add New Expense'),
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.oxfordBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        initialValue: _description,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'تفصیل' : 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? (LanguageController.isUrdu ? 'براہ کرم تفصیل درج کریں' : 'Please enter a description') : null,
                        onSaved: (val) => _description = val?.trim() ?? '',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        initialValue: isEditing ? _amount.toString() : '',
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'رقم (روپے)' : 'Amount (Rs)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.isEmpty) return LanguageController.isUrdu ? 'رقم درج کریں' : 'Enter amount';
                          if (double.tryParse(val) == null) return LanguageController.isUrdu ? 'درست نمبر درج کریں' : 'Enter valid number';
                          return null;
                        },
                        onSaved: (val) => _amount = double.parse(val!),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _defaultCategories.contains(_selectedCategory)
                            ? _selectedCategory
                            : _defaultCategories.first,
                        dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'زمرہ' : 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        items: _defaultCategories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    textDirection: LanguageController.contentTextDirection,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        initialValue: _notes,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'نوٹس (اختیاری)' : 'Notes (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        maxLines: 2,
                        onSaved: (val) => _notes = val?.trim() ?? '',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppColors.yinMnBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  setModalState(() => _isSaving = true);

                                  try {
                                    if (isEditing) {
                                      await _expenseService.updateExpense(
                                        existingExpense['id'].toString(),
                                        category: _selectedCategory,
                                        amount: _amount,
                                        description: _description,
                                        notes: _notes,
                                      );
                                    } else {
                                      await _expenseService.addExpense(
                                        category: _selectedCategory,
                                        amount: _amount,
                                        description: _description,
                                        notes: _notes,
                                      );
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(
                                          LanguageController.isUrdu ? 'آپریشن ناکام ہو گیا: $e' : 'Operation failed: $e',
                                          textDirection: LanguageController.contentTextDirection,
                                        )),
                                      );
                                    }
                                  } finally {
                                    setModalState(() => _isSaving = false);
                                  }
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing 
                                    ? (LanguageController.isUrdu ? 'خرچہ اپ ڈیٹ کریں' : 'Update Expense') 
                                    : (LanguageController.isUrdu ? 'خرچہ محفوظ کریں' : 'Save Expense'),
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        appBar: AppBar(
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
            LanguageController.isUrdu ? 'خرچہ ٹریکر' : 'Expense Tracker',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _expenseService.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  LanguageController.isUrdu ? 'خرچے لوڈ کرنے میں خرابی: ${snapshot.error}' : 'Error loading expenses: ${snapshot.error}',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? AppColors.lavender : AppColors.oxfordBlue),
                ),
              );
            }

            final expenses = snapshot.data ?? [];
            final totalExpense = expenses.fold<double>(
              0.0,
              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
            );

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.spaceCadet, AppColors.yinMnBlue, AppColors.jordyBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.45)
                              : AppColors.spaceCadet.withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          LanguageController.isUrdu ? 'کل اخراجات' : 'TOTAL EXPENSES',
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.lavender,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Rs. ${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: expenses.isEmpty
                        ? Center(
                            child: Text(
                              LanguageController.isUrdu ? 'ابھی تک کوئی خرچہ درج نہیں کیا گیا۔' : 'No expenses recorded yet.',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottomSafeArea + 130),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final item = expenses[index];
                              final id = item['id']?.toString() ?? '';
                              final category = item['category'] ?? 'General';
                              final description = item['description'] ?? '';
                              final notes = item['notes'] ?? '';
                              final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                              final dateStr = item['date'] as String?;
                              final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

                              return Dismissible(
                                key: Key(id.isNotEmpty ? id : index.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) async {
                                  if (id.isNotEmpty) {
                                    await _expenseService.deleteExpense(id);
                                    setState(() {});
                                  }
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 0,
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    side: BorderSide(
                                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                                    onTap: () => _showAddOrEditExpenseDialog(existingExpense: item),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.yinMnBlue.withValues(alpha: 0.15),
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                      ),
                                    ),
                                    title: Text(
                                      description.isNotEmpty ? description : category,
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      textDirection: LanguageController.contentTextDirection,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          '$category • ${date != null ? DateFormat('dd MMM yyyy').format(date) : ''}',
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                            color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            LanguageController.isUrdu ? 'نوٹ: $notes' : 'Note: $notes',
                                            textDirection: LanguageController.contentTextDirection,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.lavender.withValues(alpha: 0.5) : AppColors.spaceCadet.withValues(alpha: 0.5),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Text(
                                      'Rs. ${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: bottomSafeArea + 16, right: 4),
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.yinMnBlue,
            foregroundColor: Colors.white,
            onPressed: () => _showAddOrEditExpenseDialog(),
            icon: const Icon(Icons.add),
            label: Text(
              LanguageController.isUrdu ? 'خرچہ شامل کریں' : 'Add Expense',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Inventory':
        return Icons.inventory_2_rounded;
      case 'Salaries':
        return Icons.people_alt_rounded;
      case 'Transport':
        return Icons.directions_bus_rounded;
      case 'Maintenance':
        return Icons.build_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}