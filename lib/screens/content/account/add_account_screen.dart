import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/account_model.dart';
import 'package:digital_khata/services/account_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterName)),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.accountId == null
                ? l10n.accountAdded
                : l10n.accountUpdated),
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
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
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.accountId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editAccount : l10n.addAccount),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: 'e.g., Main Cash Drawer, HBL Bank',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Account type dropdown
            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              items: AccountType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: l10n.type,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // Opening balance field (only shown when creating)
            if (!isEditing) ...[
              TextField(
                controller: _openingBalanceController,
                decoration: InputDecoration(
                  labelText: l10n.openingBalance,
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixText: 'Rs. ',
                  prefixIcon: const Icon(Icons.payments),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
            ],

            // Account type information box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.type}: ${_selectedType.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? l10n.update : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}