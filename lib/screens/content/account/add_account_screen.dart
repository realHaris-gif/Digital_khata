import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/account_model.dart';
import 'package:digital_khata/services/account_service.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AddEditAccountScreen({
    Key? key,
    this.accountId,
  }) : super(key: key);

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _openingBalanceController;
  AccountType _selectedType = AccountType.cash;
  bool _isLoading = false;
  bool _isSaving = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _openingBalanceController = TextEditingController();

    if (widget.accountId != null && widget.accountId!.isNotEmpty) {
      _loadAccount();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    setState(() => _isLoading = true);
    try {
      final repository = AccountRepository(_supabase);
      final account = await repository.getAccountById(widget.accountId!);

      if (account != null && mounted) {
        setState(() {
          _nameController.text = account.name;
          _openingBalanceController.text =
              account.openingBalance.toStringAsFixed(2);
          _selectedType = account.type;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showFormSnackBar(
          context,
          message: '${l10n.error}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showFormSnackBar(
        context,
        message: l10n.pleaseEnterName,
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = AccountRepository(_supabase);
      final userId = _supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception(l10n.error);
      }

      final double openingBalance =
          double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

      if (widget.accountId == null) {
        // Create new account
        await repository.createAccount(
          userId: userId,
          name: name,
          type: _selectedType,
          openingBalance: openingBalance,
        );
      } else {
        // Update existing account
        await repository.updateAccount(
          widget.accountId!,
          name: name,
          type: _selectedType,
        );
      }

      if (mounted) {
        showFormSnackBar(
          context,
          message: widget.accountId == null
              ? l10n.accountAdded
              : l10n.accountUpdated,
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: '${l10n.error}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.accountId != null;

    return FormScaffold(
      appBar: formAppBar(
        context,
        title: isEditing ? l10n.editAccount : l10n.addAccount,
        subtitle: isEditing
            ? 'Update cash or bank account'
            : 'Create a cash or bank account',
      ),
      isLoading: _isLoading,
      bottomBar: FormBottomBar(
        primaryLabel: isEditing ? l10n.update : l10n.save,
        primaryIcon: Icons.check_rounded,
        isLoading: _isSaving,
        onPrimary: _isSaving ? null : _saveAccount,
        secondaryLabel: 'Cancel',
        onSecondary: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.pop();
          }
        },
      ),
      children: [
        FormSectionCard(
          title: 'Account details',
          subtitle: 'Name and account type',
          icon: Icons.account_balance_outlined,
          children: [
            AppFormTextField(
              controller: _nameController,
              autofocus: true,
              labelText: l10n.name,
              hintText: 'e.g., Main Cash Drawer, HBL Bank',
              prefixIcon: Icons.account_balance_wallet_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            AppFormDropdown<AccountType>(
              value: _selectedType,
              labelText: l10n.type,
              prefixIcon: Icons.category_outlined,
              items: AccountType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            if (!isEditing)
              AppFormTextField(
                controller: _openingBalanceController,
                labelText: l10n.openingBalance,
                hintText: '0.00',
                prefixText: 'Rs. ',
                prefixIcon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveAccount(),
              ),
          ],
        ),
        FormInfoBanner(
          message: '${l10n.type}: ${_selectedType.displayName}',
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
