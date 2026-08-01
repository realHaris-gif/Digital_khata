import 'package:flutter/material.dart';
import '../../../services/customer_service.dart';
import '../../../widgets/forms/form_widgets.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({Key? key}) : super(key: key);

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();

  String _name = '';
  String _phone = '';
  double _openingBalance = 0.0;
  String _address = '';
  String _notes = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        await CustomerService.addCustomer(
          name: _name,
          phone: _phone,
          openingBalance: _openingBalance,
          address: _address,
          notes: _notes,
        );

        if (mounted) {
          showFormSnackBar(
            context,
            message: 'Customer added successfully!',
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showFormSnackBar(
            context,
            message: 'Failed to add customer: $e',
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
        title: 'Add New Customer',
        subtitle: 'Create a customer profile for your ledger',
      ),
      bottomBar: FormBottomBar(
        primaryLabel: 'Save Customer',
        primaryIcon: Icons.check_rounded,
        isLoading: _isLoading,
        onPrimary: _isLoading ? null : _saveCustomer,
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
                title: 'Basic details',
                subtitle: 'Name and contact information',
                icon: Icons.person_outline_rounded,
                children: [
                  AppFormTextField(
                    focusNode: _nameFocus,
                    autofocus: true,
                    labelText: 'Customer Name *',
                    hintText: 'e.g. Ahmed Traders',
                    prefixIcon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter name'
                        : null,
                    onSaved: (val) => _name = val!.trim(),
                  ),
                  AppFormTextField(
                    labelText: 'Phone Number',
                    hintText: '+92 300 1234567',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onSaved: (val) => _phone = val?.trim() ?? '',
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Account & location',
                subtitle: 'Opening balance and address',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  AppFormTextField(
                    labelText: 'Opening Balance (Rs.)',
                    hintText: '0.00',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onSaved: (val) =>
                        _openingBalance = double.tryParse(val ?? '0') ?? 0.0,
                  ),
                  AppFormTextField(
                    labelText: 'Address',
                    hintText: 'Street, city',
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onSaved: (val) => _address = val?.trim() ?? '',
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Additional notes',
                subtitle: 'Optional remarks for this customer',
                icon: Icons.notes_outlined,
                children: [
                  AppFormTextField(
                    labelText: 'Notes',
                    hintText: 'Any extra details…',
                    prefixIcon: Icons.sticky_note_2_outlined,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSaved: (val) => _notes = val?.trim() ?? '',
                    onFieldSubmitted: (_) => _saveCustomer(),
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
