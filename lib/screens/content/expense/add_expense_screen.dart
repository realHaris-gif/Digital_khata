import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/expense_service.dart';
import '../../../widgets/forms/form_widgets.dart';

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
  final _amountFocus = FocusNode();

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

  @override
  void dispose() {
    _amountFocus.dispose();
    super.dispose();
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
      debugPrint('Error loading customers: $e');
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
          showFormSnackBar(
            context,
            message: 'Expense added successfully!',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          showFormSnackBar(
            context,
            message: 'Failed to add expense: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      appBar: formAppBar(
        context,
        title: 'Add Expense',
        subtitle: 'Record a business expense',
      ),
      bottomBar: FormBottomBar(
        primaryLabel: 'Save Expense',
        primaryIcon: Icons.check_rounded,
        isLoading: _isLoading,
        onPrimary: _isLoading ? null : _saveExpense,
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.maybePop(context),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                title: 'Expense details',
                subtitle: 'Link, categorize, and set the amount',
                icon: Icons.receipt_long_outlined,
                children: [
                  AppFormDropdown<String?>(
                    value: _selectedCustomerId,
                    labelText: 'Link to Customer (Optional)',
                    hintText: 'General Expense (No Customer)',
                    prefixIcon: Icons.person_outline_rounded,
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
                    onChanged: (val) =>
                        setState(() => _selectedCustomerId = val),
                  ),
                  AppFormDropdown<String>(
                    value: _category,
                    labelText: 'Category',
                    prefixIcon: Icons.category_outlined,
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                  AppFormTextField(
                    focusNode: _amountFocus,
                    autofocus: true,
                    labelText: 'Amount (Rs.) *',
                    hintText: '0.00',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (val) => _amount = double.parse(val!),
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Description',
                subtitle: 'Optional context for this expense',
                icon: Icons.notes_outlined,
                children: [
                  AppFormTextField(
                    labelText: 'Description',
                    hintText: 'What was this expense for?',
                    prefixIcon: Icons.description_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onSaved: (val) => _description = val?.trim() ?? '',
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    hintText: 'Any extra details…',
                    prefixIcon: Icons.sticky_note_2_outlined,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSaved: (val) => _notes = val?.trim() ?? '',
                    onFieldSubmitted: (_) => _saveExpense(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
