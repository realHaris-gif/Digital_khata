import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? invoiceToEdit;

  const AddEditInvoiceScreen({Key? key, this.invoiceToEdit}) : super(key: key);

  @override
  ConsumerState<AddEditInvoiceScreen> createState() =>
      _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _notesController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _shippingController;

  String? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];
  List<Product> _availableProducts = [];

  InvoiceStatus _selectedStatus = InvoiceStatus.draft;
  String _discountType = 'flat';
  String _taxType = 'flat';

  List<InvoiceItem> _items = [];
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditing => widget.invoiceToEdit != null;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    final inv = widget.invoiceToEdit;

    _invoiceNumberController =
        TextEditingController(text: inv?.invoiceNumber ?? '');
    _notesController = TextEditingController(text: inv?.notes ?? '');
    _discountController =
        TextEditingController(text: inv?.discount.toString() ?? '0');
    _taxController = TextEditingController(text: inv?.tax.toString() ?? '0');
    _shippingController =
        TextEditingController(text: inv?.shipping.toString() ?? '0');

    _selectedCustomerId = inv?.customerId;
    _selectedStatus = inv?.status ?? InvoiceStatus.draft;
    _discountType = inv?.discountType ?? 'flat';
    _taxType = inv?.taxType ?? 'flat';
    _items = inv?.items != null ? List.from(inv!.items) : [];

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    try {
      if (!_isEditing && userId.isNotEmpty) {
        final repo = ref.read(invoiceRepoProvider);
        final nextNum = await repo.generateNextInvoiceNumber(userId);
        _invoiceNumberController.text = nextNum;
      }

      final loadedCustomers = await CustomerService.getCustomersAlphabetically();
      final invRepo = ref.read(inventoryRepoProvider);
      final loadedProducts = await invRepo.getProducts(userId: userId);

      if (mounted) {
        setState(() {
          _customers = loadedCustomers;
          _availableProducts = loadedProducts;

          if (_selectedCustomerId != null &&
              !_customers
                  .any((c) => c['id'].toString() == _selectedCustomerId)) {
            _selectedCustomerId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'آپشنز لوڈ کرنے میں خرابی: $e' : 'Error loading options: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addNewCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
          ),
          title: Text(
            LanguageController.isUrdu ? 'نیا گاہک شامل کریں' : 'Add New Customer',
            textDirection: LanguageController.contentTextDirection,
          ),
          content: Form(
            key: dialogKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFormTextField(
                  controller: nameCtrl,
                  autofocus: true,
                  labelText: LanguageController.isUrdu ? 'گاہک کا نام *' : 'Customer Name *',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? (LanguageController.isUrdu ? 'نام درج کریں' : 'Enter name') : null,
                ),
                const SizedBox(height: 12),
                AppFormTextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  labelText: LanguageController.isUrdu ? 'فون نمبر (اختیاری)' : 'Phone Number (Optional)',
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            FormSecondaryButton(
              label: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
              onPressed: () => Navigator.pop(ctx),
            ),
            FormPrimaryButton(
              label: LanguageController.isUrdu ? 'گاہک محفوظ کریں' : 'Save Customer',
              onPressed: () async {
                if (!dialogKey.currentState!.validate()) return;

                try {
                  final newCustomer = await CustomerService.addCustomer(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );

                  Navigator.pop(ctx);
                  await _loadData();

                  setState(() {
                    _selectedCustomerId = newCustomer['id'].toString();
                  });
                } catch (e) {
                  showFormSnackBar(
                    context,
                    message: LanguageController.isUrdu ? 'گاہک شامل کرنے میں خرابی: $e' : 'Error adding customer: $e',
                    isError: true,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _calculatedDiscount {
    final val = double.tryParse(_discountController.text.trim()) ?? 0.0;
    if (_discountType == 'percentage') {
      return (_subtotal * val) / 100.0;
    }
    return val;
  }

  double get _calculatedTax {
    final val = double.tryParse(_taxController.text.trim()) ?? 0.0;
    final taxableAmount =
        (_subtotal - _calculatedDiscount).clamp(0.0, double.infinity);
    if (_taxType == 'percentage') {
      return (taxableAmount * val) / 100.0;
    }
    return val;
  }

  double get _shipping =>
      double.tryParse(_shippingController.text.trim()) ?? 0.0;

  double get _grandTotal =>
      (_subtotal - _calculatedDiscount + _calculatedTax + _shipping)
          .clamp(0.0, double.infinity);

  void _addItemDialog() {
    String? selectedProductId;
    String searchQuery = '';
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0');
    final itemDiscountCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredProducts = _availableProducts.where((p) {
              final query = searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(query) ||
                  (p.sku != null && p.sku!.toLowerCase().contains(query));
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
              ),
              title: Text(
                LanguageController.isUrdu ? 'انوائس میں آئ템 شامل کریں' : 'Add Item to Invoice',
                textDirection: LanguageController.contentTextDirection,
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_availableProducts.isEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final res =
                                await context.push('/inventory/add-product');
                            if (res == true) _loadData();
                          },
                          icon: Icon(Icons.add_rounded, color: yinMnBlue),
                          label: Text(
                            LanguageController.isUrdu ? 'اسٹاک میں کوئی پروڈکٹ نہیں ہے۔ شامل کرنے کے لیے ٹیپ کریں!' : 'No products in stock. Tap to add!',
                            textDirection: LanguageController.contentTextDirection,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppFormTokens.radiusMd),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        TextField(
                          decoration: appInputDecoration(
                            context,
                            hintText: LanguageController.isUrdu ? 'نام یا ایس کے یو کے ذریعے پروڈکٹ تلاش کریں...' : 'Search product by name or SKU...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                          ),
                          textDirection: LanguageController.contentTextDirection,
                          onChanged: (val) {
                            setModalState(() => searchQuery = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        AppFormDropdown<String>(
                          value: selectedProductId,
                          labelText: LanguageController.isUrdu ? 'پروڈکٹ منتخب کریں' : 'Select Product',
                          hintText: LanguageController.isUrdu ? 'اسٹاک میں سے منتخب کریں...' : 'Choose from stock...',
                          prefixIcon: Icons.inventory_2_outlined,
                          items: filteredProducts.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                '${p.name} (Rs. ${p.sellingPrice} | Stock: ${p.currentStock.toStringAsFixed(0)})',
                                textDirection: TextDirection.ltr,
                              ),
                            );
                          }).toList(),
                          onChanged: (pId) {
                            if (pId != null) {
                              final p = _availableProducts
                                  .firstWhere((item) => item.id == pId);
                              setModalState(() {
                                selectedProductId = p.id;
                                nameCtrl.text = p.name;
                                priceCtrl.text = p.sellingPrice.toString();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppFormTextField(
                        controller: nameCtrl,
                        autofocus: _availableProducts.isEmpty,
                        labelText: LanguageController.isUrdu ? 'آئٹম کا نام *' : 'Item Name *',
                        prefixIcon: Icons.shopping_bag_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? (LanguageController.isUrdu ? 'آئٹم کا نام درج کریں' : 'Enter item name')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppFormTextField(
                              controller: qtyCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              labelText: LanguageController.isUrdu ? 'مقدار *' : 'Quantity *',
                              prefixIcon: Icons.pin_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return LanguageController.isUrdu ? 'مقدار درج کریں' : 'Enter Qty';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return LanguageController.isUrdu ? 'غلط مقدار' : 'Invalid Qty';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFormTextField(
                              controller: priceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              labelText: LanguageController.isUrdu ? 'قیمت (روپے) *' : 'Price (Rs.) *',
                              prefixIcon: Icons.sell_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? (LanguageController.isUrdu ? 'قیمت درج کریں' : 'Enter Price')
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppFormTextField(
                        controller: itemDiscountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        labelText: LanguageController.isUrdu ? 'آئٹم ڈسکاؤنٹ (روپے)' : 'Item Discount (Rs.)',
                        prefixIcon: Icons.discount_outlined,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                FormSecondaryButton(
                  label: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                  onPressed: () => Navigator.pop(ctx),
                ),
                FormPrimaryButton(
                  label: LanguageController.isUrdu ? 'آئٹم شامل کریں' : 'Add Item',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                    final price = double.parse(priceCtrl.text.trim());
                    final disc =
                        double.tryParse(itemDiscountCtrl.text.trim()) ?? 0.0;
                    final lineTotal =
                        (qty * price - disc).clamp(0.0, double.infinity);

                    setState(() {
                      _items.add(
                        InvoiceItem(
                          id: '',
                          invoiceId: widget.invoiceToEdit?.id ?? '',
                          productId: selectedProductId,
                          productName: nameCtrl.text.trim(),
                          quantity: qty,
                          unitPrice: price,
                          discount: disc,
                          tax: 0.0,
                          lineTotal: lineTotal,
                          createdAt: DateTime.now(),
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      showFormSnackBar(
        context,
        message: LanguageController.isUrdu ? 'براہ کرم کم از کم ایک آئٹم شامل کریں۔' : 'Please add at least one item.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final repo = ref.read(invoiceRepoProvider);

    try {
      if (_isEditing) {
        await repo.updateInvoice(
          invoiceId: widget.invoiceToEdit!.id,
          userId: userId,
          customerId: _selectedCustomerId,
          invoiceNumber: _invoiceNumberController.text.trim(),
          status: _selectedStatus,
          subtotal: _subtotal,
          discount: double.tryParse(_discountController.text.trim()) ?? 0.0,
          discountType: _discountType,
          tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
          taxType: _taxType,
          shipping: _shipping,
          total: _grandTotal,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: _items,
        );
      } else {
        await repo.createInvoice(
          userId: userId,
          customerId: _selectedCustomerId,
          invoiceNumber: _invoiceNumberController.text.trim(),
          status: _selectedStatus,
          subtotal: _subtotal,
          discount: double.tryParse(_discountController.text.trim()) ?? 0.0,
          discountType: _discountType,
          tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
          taxType: _taxType,
          shipping: _shipping,
          total: _grandTotal,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: _items,
        );
      }

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'انوائس محفوظ کرنے میں خرابی: $e' : 'Error saving invoice: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _typeChip({
    required String value,
    required String groupValue,
    required String label,
    required ValueChanged<String> onSelected,
  }) {
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: yinMnBlue.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? yinMnBlue : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected
            ? yinMnBlue.withValues(alpha: 0.4)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppFormTokens.radiusSm),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          title: _isEditing ? (LanguageController.isUrdu ? 'انوائس میں ترمیم کریں' : 'Edit Invoice') : (LanguageController.isUrdu ? 'نئی انوائس' : 'New Invoice'),
          subtitle: _isEditing
              ? (LanguageController.isUrdu ? 'انوائس کی تفصیلات اور آئٹمز اپ ڈیٹ کریں' : 'Update invoice details and items')
              : (LanguageController.isUrdu ? 'ایک پیشہ ورانہ انوائس بنائیں' : 'Create a professional invoice'),
        ),
        isLoading: _isLoading,
        bottomBar: FormBottomBar(
          primaryLabel: _isEditing ? (LanguageController.isUrdu ? 'انوائس اپ ڈیٹ کریں' : 'Update Invoice') : (LanguageController.isUrdu ? 'انوائس محفوظ کریں' : 'Save Invoice'),
          primaryIcon: Icons.check_rounded,
          isLoading: _isSaving,
          onPrimary: _isSaving ? null : _saveInvoice,
          secondaryLabel: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
          onSecondary: () => context.pop(),
        ),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'انوائس کی تفصیلات' : 'Invoice details',
                  subtitle: LanguageController.isUrdu ? 'نمبر، حیثیت، اور گاہک' : 'Number, status, and customer',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            controller: _invoiceNumberController,
                            autofocus: true,
                            labelText: LanguageController.isUrdu ? 'انوائس نمبر *' : 'Invoice # *',
                            prefixIcon: Icons.tag_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? (LanguageController.isUrdu ? 'انوائس نمبر درج کریں' : 'Enter invoice #')
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppFormDropdown<InvoiceStatus>(
                            value: _selectedStatus,
                            labelText: LanguageController.isUrdu ? 'حالت' : 'Status',
                            prefixIcon: Icons.flag_outlined,
                            items: InvoiceStatus.values.map((st) {
                              return DropdownMenuItem<InvoiceStatus>(
                                value: st,
                                child: Text(
                                  st.value,
                                  textDirection: LanguageController.contentTextDirection,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFormDropdown<String?>(
                            value: _selectedCustomerId,
                            labelText: LanguageController.isUrdu ? 'گاہک منتخب کریں' : 'Select Customer',
                            hintText: LanguageController.isUrdu ? 'ایک گاہک منتخب کریں...' : 'Choose a customer...',
                            prefixIcon: Icons.person_outline_rounded,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  LanguageController.isUrdu ? 'واک ان کسٹمر' : 'Walk-in Customer',
                                  textDirection: LanguageController.contentTextDirection,
                                ),
                              ),
                              ..._customers.map((c) {
                                return DropdownMenuItem<String?>(
                                  value: c['id'].toString(),
                                  child: Text(
                                    c['name'] as String? ?? (LanguageController.isUrdu ? 'نامعلوم گاہک' : 'Unnamed Customer'),
                                    textDirection: LanguageController.contentTextDirection,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedCustomerId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton.filledTonal(
                            onPressed: _addNewCustomerDialog,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            tooltip: LanguageController.isUrdu ? 'نیا گاہک شامل کریں' : 'Add New Customer',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppFormTokens.radiusMd),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'انوائس آئٹمز' : 'Invoice items',
                  subtitle: LanguageController.isUrdu ? 'اس بل پر پروڈکٹس اور لائن آئٹمز' : 'Products and line items on this bill',
                  icon: Icons.list_alt_rounded,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: yinMnBlue.withValues(alpha: 0.15),
                          foregroundColor: isDark ? jordyBlue : yinMnBlue,
                        ),
                        onPressed: _addItemDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          LanguageController.isUrdu ? 'آئٹم شامل کریں' : 'Add Item',
                          textDirection: LanguageController.contentTextDirection,
                        ),
                      ),
                    ),
                    if (_items.isEmpty)
                      FormEmptyState(
                        message: LanguageController.isUrdu ? 'انوائس میں ابھی تک کوئی آئٹم شامل نہیں کیا گیا۔' : 'No items added to invoice yet.',
                        icon: Icons.shopping_cart_outlined,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 20,
                          color: cs.outline.withValues(alpha: 0.12),
                        ),
                        itemBuilder: (ctx, idx) {
                          return InvoiceItemTile(
                            item: _items[idx],
                            onDelete: () {
                              setState(() => _items.removeAt(idx));
                            },
                          );
                        },
                      ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'کل رقم' : 'Totals',
                  subtitle: LanguageController.isUrdu ? 'ڈسکاؤنٹ، ٹیکس، شپنگ، اور کل رقم' : 'Discount, tax, shipping, and grand total',
                  icon: Icons.calculate_outlined,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LanguageController.isUrdu ? 'ذیلی کل' : 'Subtotal',
                          textDirection: LanguageController.contentTextDirection,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          'Rs. ${_subtotal.toStringAsFixed(2)}',
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            labelText: LanguageController.isUrdu ? 'ڈسکاؤنٹ' : 'Discount',
                            prefixIcon: Icons.discount_outlined,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _typeChip(
                                value: 'flat',
                                groupValue: _discountType,
                                label: 'Rs.',
                                onSelected: (v) =>
                                    setState(() => _discountType = v),
                              ),
                              const SizedBox(width: 6),
                              _typeChip(
                                value: 'percentage',
                                groupValue: _discountType,
                                label: '%',
                                onSelected: (v) =>
                                    setState(() => _discountType = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            controller: _taxController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            labelText: LanguageController.isUrdu ? 'ٹیکس' : 'Tax',
                            prefixIcon: Icons.percent_rounded,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _typeChip(
                                value: 'flat',
                                groupValue: _taxType,
                                label: 'Rs.',
                                onSelected: (v) => setState(() => _taxType = v),
                              ),
                              const SizedBox(width: 6),
                              _typeChip(
                                value: 'percentage',
                                groupValue: _taxType,
                                label: '%',
                                onSelected: (v) => setState(() => _taxType = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppFormTextField(
                      controller: _shippingController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      labelText: LanguageController.isUrdu ? 'شپنگ چارجز (روپے)' : 'Shipping Charges (Rs.)',
                      prefixIcon: Icons.local_shipping_outlined,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: yinMnBlue.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.radiusMd),
                        border: Border.all(
                          color: yinMnBlue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LanguageController.isUrdu ? 'کل رقم' : 'Grand Total',
                            textDirection: LanguageController.contentTextDirection,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? jordyBlue : yinMnBlue,
                                    ),
                          ),
                          Text(
                            'Rs. ${_grandTotal.toStringAsFixed(2)}',
                            textDirection: TextDirection.ltr,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? jordyBlue : yinMnBlue,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'نوٹس' : 'Notes',
                  subtitle: LanguageController.isUrdu ? 'شرائط و ضوابط یا ریمارکس' : 'Terms & conditions or remarks',
                  icon: Icons.notes_outlined,
                  children: [
                    AppFormTextField(
                      controller: _notesController,
                      maxLines: 3,
                      labelText: LanguageController.isUrdu ? 'نوٹس / شرائط و ضوابط' : 'Notes / Terms & Conditions',
                      hintText: LanguageController.isUrdu ? 'ادائیگی کی شرائط، ڈیلیوری کے نوٹس…' : 'Payment terms, delivery notes…',
                      prefixIcon: Icons.sticky_note_2_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
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