import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/supplier_service.dart';

class AddEditSupplierScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const AddEditSupplierScreen({
    Key? key,
    this.supplierId,
  }) : super(key: key);

  @override
  ConsumerState<AddEditSupplierScreen> createState() =>
      _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends ConsumerState<AddEditSupplierScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _openingBalanceController;
  
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
    _openingBalanceController = TextEditingController();

    if (widget.supplierId != null && widget.supplierId!.isNotEmpty) {
      _loadSupplier();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplier() async {
    setState(() => _isLoading = true);
    try {
      final repository = SupplierRepository(_supabase);
      final supplier = await repository.getSupplierById(widget.supplierId!);

      if (supplier != null && mounted) {
        setState(() {
          _nameController.text = supplier.name;
          _phoneController.text = supplier.phone ?? '';
          _addressController.text = supplier.address ?? '';
          _notesController.text = supplier.notes ?? '';
          _openingBalanceController.text =
              supplier.openingBalance.toStringAsFixed(2);
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

  Future<void> _saveSupplier() async {
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
      final repository = SupplierRepository(_supabase);
      final userId = _supabase.auth.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception(l10n.error);
      }

      final double openingBalance =
          double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

      if (widget.supplierId == null) {
        // Create new supplier
        await repository.createSupplier(
          userId: userId,
          name: name,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          openingBalance: openingBalance,
        );
      } else {
        // Update existing supplier
        await repository.updateSupplier(
          widget.supplierId!,
          name: name,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          openingBalance: openingBalance,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.supplierId == null
                ? l10n.supplierAdded
                : l10n.supplierUpdated),
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
    final isEditing = widget.supplierId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editSupplier : l10n.addSupplier),
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
                hintText: 'e.g., ABC Suppliers',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Phone field
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phone,
                hintText: '+92 300 1234567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Address field
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.address,
                hintText: 'Street address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Opening balance field
            TextField(
              controller: _openingBalanceController,
              decoration: InputDecoration(
                labelText: l10n.openingBalance,
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                hintText: 'Add notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSupplier,
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