import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/services/supplier_service.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

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

class _AddEditSupplierScreenState
    extends ConsumerState<AddEditSupplierScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _openingBalanceController;

  bool _isLoading = false;
  bool _isSaving = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

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

  Future<void> _saveSupplier() async {
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
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          openingBalance: openingBalance,
        );
      } else {
        // Update existing supplier
        await repository.updateSupplier(
          widget.supplierId!,
          name: name,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          openingBalance: openingBalance,
        );
      }

      if (mounted) {
        showFormSnackBar(
          context,
          message: widget.supplierId == null
              ? l10n.supplierAdded
              : l10n.supplierUpdated,
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
    final isEditing = widget.supplierId != null;
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: FormScaffold(
        appBar: formAppBar(
          context,
          title: isEditing 
              ? (LanguageController.isUrdu ? 'سپلائر میں ترمیم کریں' : l10n.editSupplier) 
              : (LanguageController.isUrdu ? 'سپلائر شامل کریں' : l10n.addSupplier),
          subtitle: isEditing
              ? (LanguageController.isUrdu ? 'سپلائر کی معلومات اپ ڈیٹ کریں' : 'Update supplier information')
              : (LanguageController.isUrdu ? 'اپنے کاروبار میں ایک نیا سپلائر شامل کریں' : 'Add a new supplier to your business'),
        ),
        isLoading: _isLoading,
        bottomBar: FormBottomBar(
          primaryLabel: isEditing 
              ? (LanguageController.isUrdu ? 'اپ ڈیٹ کریں' : l10n.update) 
              : (LanguageController.isUrdu ? 'محفوظ کریں' : l10n.save),
          primaryIcon: Icons.check_rounded,
          isLoading: _isSaving,
          onPrimary: _isSaving ? null : _saveSupplier,
          secondaryLabel: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
          onSecondary: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.pop();
            }
          },
        ),
        children: [
          _isSaving
              ? _buildSkeletonLoadingState(isDark)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    FormSectionCard(
                      title: LanguageController.isUrdu ? 'سپلائر کی تفصیلات' : 'Supplier details',
                      subtitle: LanguageController.isUrdu ? 'نام اور رابطہ کی معلومات' : 'Name and contact information',
                      icon: Icons.storefront_outlined,
                      children: [
                        AppFormTextField(
                          controller: _nameController,
                          autofocus: true,
                          labelText: l10n.name,
                          hintText: LanguageController.isUrdu ? 'مثال کے طور پر، اے بی سی سپلائرز' : 'e.g., ABC Suppliers',
                          prefixIcon: Icons.business_outlined,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          controller: _phoneController,
                          labelText: l10n.phone,
                          hintText: '03001234567',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 11) {
                              return LanguageController.isUrdu ? 'فون نمبر بالکل 11 ہندسوں کا ہونا چاہیے' : 'Phone number must be exactly 11 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          controller: _addressController,
                          labelText: l10n.address,
                          hintText: LanguageController.isUrdu ? 'گلی کا پتہ' : 'Street address',
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    FormSectionCard(
                      title: LanguageController.isUrdu ? 'مالیاتی' : 'Financial',
                      subtitle: LanguageController.isUrdu ? 'اس سپلائر کے لیے افتتاحی بیلنس' : 'Opening balance for this supplier',
                      icon: Icons.account_balance_outlined,
                      children: [
                        AppFormTextField(
                          controller: _openingBalanceController,
                          labelText: l10n.openingBalance,
                          hintText: '0.00',
                          prefixIcon: Icons.payments_outlined,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    FormSectionCard(
                      title: LanguageController.isUrdu ? 'نوٹس' : 'Notes',
                      subtitle: LanguageController.isUrdu ? 'اختیاری ریمارکس' : 'Optional remarks',
                      icon: Icons.notes_outlined,
                      children: [
                        AppFormTextField(
                          controller: _notesController,
                          labelText: l10n.notes,
                          hintText: LanguageController.isUrdu ? 'نوٹس شامل کریں...' : 'Add notes...',
                          prefixIcon: Icons.sticky_note_2_outlined,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _saveSupplier(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ],
      ),
    );
  }

  // Skeleton Loader Shimmer State
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 90, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 110, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
            ],
          ),
        );
      },
    );
  }
}