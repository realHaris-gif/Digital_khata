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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Please enter a description' : null,
                        onSaved: (val) => _description = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: isEditing ? _amount.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Amount (Rs)',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onSaved: (val) => _notes = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
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
                            : Text(isEditing ? 'Update Expense' : 'Save Expense'),
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
              child: Text('Error loading expenses: ${snapshot.error}'),
            );
          }

          final expenses = snapshot.data ?? [];
          final totalExpense = expenses.fold<double>(
            0.0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
          );

          return Column(
            children: [
              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Expenses List
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses recorded yet.'))
                    : ListView.builder(
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
                              color: Colors.red,
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
                            child: ListTile(
                              onTap: () => _showAddOrEditExpenseDialog(existingExpense: item),
                              leading: CircleAvatar(
                                child: Icon(_getCategoryIcon(category)),
                              ),
                              title: Text(
                                description.isNotEmpty ? description : category,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$category • ${date != null ? DateFormat('dd MMM yyyy').format(date) : ''}',
                                  ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      'Note: $notes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                'Rs. ${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 15,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditExpenseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home;
      case 'Utilities':
        return Icons.bolt;
      case 'Inventory':
        return Icons.inventory;
      case 'Salaries':
        return Icons.people;
      case 'Transport':
        return Icons.directions_bus;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.receipt_long;
    }
  }
}