import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? initialCustomerId;
  final String? initialCustomerName;

  const AddExpenseScreen({
    Key? key,
    this.initialCustomerId,
    this.initialCustomerName,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseService _expenseService = ExpenseService();
  final SupabaseClient _client = Supabase.instance.client;

  String _category = 'General';
  double _amount = 0.0;
  String _description = '';
  String _notes = '';
  String? _selectedCustomerId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _customers = [];

  final List<String> _categories = [
    'General',
    'Transport',
    'Packaging',
    'Rent',
    'Utilities',
    'Inventory',
    'Salaries',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _client
          .from('customers')
          .select('id, name')
          .eq('created_by', userId)
          .order('name', ascending: true);

      setState(() {
        _customers = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      print('Error loading customers: $e');
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        await _expenseService.addExpense(
          category: _category,
          amount: _amount,
          customerId: _selectedCustomerId,
          description: _description,
          notes: _notes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add expense: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection Dropdown
              DropdownButtonFormField<String?>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Link to Customer (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('General Expense (No Customer)'),
                  ),
                  ..._customers.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c['id'] as String,
                      child: Text(c['name'] ?? 'Unknown'),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCustomerId = val),
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                onSaved: (val) => _description = val?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
                onSaved: (val) => _notes = val?.trim() ?? '',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveExpense,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Expense',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}