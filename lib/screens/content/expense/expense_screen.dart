import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    children: [
                      Text(
                        isEditing ? 'Edit Expense' : 'Add New Expense',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _description,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Please enter a description' : null,
                        onSaved: (val) => _description = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: isEditing ? _amount.toString() : '',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Amount (Rs)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null) return 'Enter valid number';
                          return null;
                        },
                        onSaved: (val) => _amount = double.parse(val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _defaultCategories.contains(_selectedCategory)
                            ? _selectedCategory
                            : _defaultCategories.first,
                        dropdownColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _defaultCategories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _notes,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                        onSaved: (val) => _notes = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: isDark ? Colors.tealAccent.shade700 : Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

                                    if (mounted) {
                                      Navigator.pop(context);
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Operation failed: $e')),
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
                                isEditing ? 'Update Expense' : 'Save Expense',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _expenseService.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading expenses: ${snapshot.error}',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black87),
              ),
            );
          }

          final expenses = snapshot.data ?? [];
          final totalExpense = expenses.fold<double>(
            0.0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
          );

          return Column(
            children: [
              // Theme-Adaptive Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : theme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL EXPENSES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        // High-contrast color fix for dark mode
                        color: isDark ? Colors.white : theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Expenses List View
              Expanded(
                child: expenses.isEmpty
                    ? Center(
                        child: Text(
                          'No expenses recorded yet.',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        // Extra bottom padding ensures last item is clear of floating action button & footer bar
                        padding: const EdgeInsets.only(bottom: 120),
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
                              color: Colors.redAccent,
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
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              elevation: 0,
                              color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                onTap: () => _showAddOrEditExpenseDialog(existingExpense: item),
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? Colors.white12 : theme.primaryColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: isDark ? Colors.tealAccent : theme.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  description.isNotEmpty ? description : category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$category • ${date != null ? DateFormat('dd MMM yyyy').format(date) : ''}',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (notes.isNotEmpty)
                                      Text(
                                        'Note: $notes',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  'Rs. ${amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.redAccent.shade100 : Colors.redAccent,
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
          );
        },
      ),


      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80, right: 8), // Keeps FAB elevated above bottom nav bar
        child: FloatingActionButton.extended(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          onPressed: () => _showAddOrEditExpenseDialog(),
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Expense',
            style: TextStyle(fontWeight: FontWeight.bold),
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