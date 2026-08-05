import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
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

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

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
            message: LanguageController.isUrdu ? 'خسرہ کامیابی کے ساتھ شامل کر دیا گیا!' : 'Expense added successfully!',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          showFormSnackBar(
            context,
            message: LanguageController.isUrdu ? 'خسرہ شامل کرنے میں ناکام: $e' : 'Failed to add expense: $e',
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
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: yinMnBlue,
            ),
      ),
      child: FormScaffold(
        appBar: formAppBar(
          context,
          title: LanguageController.isUrdu ? 'خرچہ شامل کریں' : 'Add Expense',
          subtitle: LanguageController.isUrdu ? 'کاروباری خرچہ درج کریں' : 'Record a business expense',
        ),
        bottomBar: FormBottomBar(
          primaryLabel: LanguageController.isUrdu ? 'خرچہ محفوظ کریں' : 'Save Expense',
          primaryIcon: Icons.check_rounded,
          isLoading: _isLoading,
          onPrimary: _isLoading ? null : _saveExpense,
          secondaryLabel: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
          onSecondary: () => Navigator.maybePop(context),
        ),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'خرچے کی تفصیلات' : 'Expense details',
                  subtitle: LanguageController.isUrdu ? 'لنک کریں، زمرہ منتخب کریں، اور رقم درج کریں' : 'Link, categorize, and set the amount',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    AppFormDropdown<String?>(
                      value: _selectedCustomerId,
                      labelText: LanguageController.isUrdu ? 'گاہک سے لنک کریں (اختیاری)' : 'Link to Customer (Optional)',
                      hintText: LanguageController.isUrdu ? 'جنرل خرچہ (کوئی گاہک نہیں)' : 'General Expense (No Customer)',
                      prefixIcon: Icons.person_outline_rounded,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            LanguageController.isUrdu ? 'جنرل خرچہ (کوئی گاہک نہیں)' : 'General Expense (No Customer)',
                            textDirection: LanguageController.contentTextDirection,
                          ),
                        ),
                        ..._customers.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c['id'] as String,
                            child: Text(
                              c['name'] ?? (LanguageController.isUrdu ? 'نامعلوم' : 'Unknown'),
                              textDirection: LanguageController.contentTextDirection,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedCustomerId = val),
                    ),
                    AppFormDropdown<String>(
                      value: _category,
                      labelText: LanguageController.isUrdu ? 'زمرہ' : 'Category',
                      prefixIcon: Icons.category_outlined,
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(
                                  value: cat, 
                                  child: Text(
                                    cat,
                                    textDirection: LanguageController.contentTextDirection,
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                    AppFormTextField(
                      focusNode: _amountFocus,
                      autofocus: true,
                      labelText: LanguageController.isUrdu ? 'رقم (روپے) *' : 'Amount (Rs.) *',
                      hintText: '0.00',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return LanguageController.isUrdu ? 'براہ کرم رقم درج کریں' : 'Please enter an amount';
                        }
                        if (double.tryParse(val) == null) {
                          return LanguageController.isUrdu ? 'درست نمبر درج کریں' : 'Enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (val) => _amount = double.parse(val!),
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'تفصیل' : 'Description',
                  subtitle: LanguageController.isUrdu ? 'اس خرچے کے لیے اختیاری سیاق و سباق' : 'Optional context for this expense',
                  icon: Icons.notes_outlined,
                  children: [
                    AppFormTextField(
                      labelText: LanguageController.isUrdu ? 'تفصیل' : 'Description',
                      hintText: LanguageController.isUrdu ? 'یہ خرچہ کس چیز کے لیے تھا؟' : 'What was this expense for?',
                      prefixIcon: Icons.description_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onSaved: (val) => _description = val?.trim() ?? '',
                    ),
                    AppFormTextField(
                      labelText: LanguageController.isUrdu ? 'نوٹس' : 'Notes',
                      hintText: LanguageController.isUrdu ? 'کوئی اضافی تفصیلات…' : 'Any extra details…',
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
      ),
    );
  }
}