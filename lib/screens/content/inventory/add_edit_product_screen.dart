import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _initialStockController;
  late TextEditingController _minimumStockController;
  late TextEditingController _unitController;

  String? _selectedCategoryId;
  bool _isLoading = false;
  List<Category> _categories = [];

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _purchasePriceController =
        TextEditingController(text: p?.purchasePrice.toString() ?? '0');
    _sellingPriceController =
        TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _initialStockController =
        TextEditingController(text: p?.currentStock.toString() ?? '0');
    _minimumStockController =
        TextEditingController(text: p?.minimumStock.toString() ?? '5');
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');

    _selectedCategoryId = p?.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final repo = ref.read(inventoryRepoProvider);
      final list = await repo.getCategories(userId);
      if (mounted) {
        setState(() {
          _categories = list;
          if (_selectedCategoryId != null &&
              !_categories.any((cat) => cat.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      // Gracefully handle category load error
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _initialStockController.dispose();
    _minimumStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final repo = ref.read(inventoryRepoProvider);

    try {
      if (_isEditing) {
        await repo.updateProduct(
          productId: widget.productToEdit!.id,
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          purchasePrice:
              double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
          sellingPrice:
              double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
          minimumStock:
              double.tryParse(_minimumStockController.text.trim()) ?? 0.0,
          unit: _unitController.text.trim().isEmpty
              ? 'pcs'
              : _unitController.text.trim(),
        );
      } else {
        await repo.createProduct(
          userId: userId,
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          purchasePrice:
              double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
          sellingPrice:
              double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
          initialStock:
              double.tryParse(_initialStockController.text.trim()) ?? 0.0,
          minimumStock:
              double.tryParse(_minimumStockController.text.trim()) ?? 0.0,
          unit: _unitController.text.trim().isEmpty
              ? 'pcs'
              : _unitController.text.trim(),
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'پروڈکٹ محفوظ کرنے میں خرابی: $e' : 'Error saving product: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: yinMnBlue,
            ),
      ),
      child: FormScaffold(
        appBar: formAppBar(
          context,
          title: _isEditing ? (LanguageController.isUrdu ? 'پروڈکٹ میں ترمیم کریں' : 'Edit Product') : (LanguageController.isUrdu ? 'نیا پروڈکٹ شامل کریں' : 'Add New Product'),
          subtitle: _isEditing
              ? (LanguageController.isUrdu ? 'پروڈکٹ کی تفصیلات اور قیمتیں اپ ڈیٹ کریں' : 'Update product details and pricing')
              : (LanguageController.isUrdu ? 'اپنے انوینٹری میں پروڈکٹ شامل کریں' : 'Add a product to your inventory'),
        ),
        bottomBar: FormBottomBar(
          primaryLabel: _isEditing ? (LanguageController.isUrdu ? 'پروڈکٹ اپ ڈیٹ کریں' : 'Update Product') : (LanguageController.isUrdu ? 'پروڈکٹ محفوظ کریں' : 'Save Product'),
          primaryIcon: Icons.check_rounded,
          isLoading: _isLoading,
          onPrimary: _isLoading ? null : _saveProduct,
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
                  title: LanguageController.isUrdu ? 'پروڈکٹ کی شناخت' : 'Product identity',
                  subtitle: LanguageController.isUrdu ? 'نام، زمرہ، اور شناختی نمبر' : 'Name, category, and identifiers',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    AppFormTextField(
                      controller: _nameController,
                      autofocus: true,
                      labelText: LanguageController.isUrdu ? 'پروڈکٹ کا نام *' : 'Product Name *',
                      hintText: LanguageController.isUrdu ? 'مثال کے طور پر، پریمیم چائے 500 گرام' : 'e.g. Premium Tea 500g',
                      prefixIcon: Icons.shopping_bag_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? (LanguageController.isUrdu ? 'نام درج کریں' : 'Enter name')
                          : null,
                    ),
                    AppFormDropdown<String?>(
                      value: _selectedCategoryId,
                      labelText: LanguageController.isUrdu ? 'زمرہ' : 'Category',
                      hintText: LanguageController.isUrdu ? 'ایک زمرہ منتخب کریں (اختیاری)' : 'Select a category (Optional)',
                      prefixIcon: Icons.category_outlined,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            LanguageController.isUrdu ? 'کوئی نہیں / جنرل' : 'None / General',
                            textDirection: LanguageController.contentTextDirection,
                          ),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(
                              cat.name,
                              textDirection: LanguageController.contentTextDirection,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            controller: _skuController,
                            labelText: LanguageController.isUrdu ? 'SKU / کوڈ' : 'SKU / Code',
                            hintText: 'SKU-001',
                            prefixIcon: Icons.tag_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppFormTextField(
                            controller: _unitController,
                            labelText: LanguageController.isUrdu ? 'یونٹ' : 'Unit',
                            hintText: 'pcs, kg, box',
                            prefixIcon: Icons.straighten_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    AppFormTextField(
                      controller: _barcodeController,
                      labelText: LanguageController.isUrdu ? 'بارکوڈ نمبر' : 'Barcode Number',
                      hintText: LanguageController.isUrdu ? 'بارکوڈ اسکین کریں یا ٹائپ کریں' : 'Scan or type barcode',
                      prefixIcon: Icons.qr_code_2_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'قیمتیں' : 'Pricing',
                  subtitle: LanguageController.isUrdu ? 'خریداری اور فروخت کی شرحیں' : 'Purchase and selling rates',
                  icon: Icons.payments_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: AppFormTextField(
                            controller: _purchasePriceController,
                            labelText: LanguageController.isUrdu ? 'خریداری کی قیمت (روپے)' : 'Purchase Price (Rs.)',
                            hintText: '0.00',
                            prefixIcon: Icons.shopping_cart_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppFormTextField(
                            controller: _sellingPriceController,
                            labelText: LanguageController.isUrdu ? 'فروخت کی قیمت (روپے) *' : 'Selling Price (Rs.) *',
                            hintText: '0.00',
                            prefixIcon: Icons.sell_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? (LanguageController.isUrdu ? 'قیمت درج کریں' : 'Enter price')
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'اسٹاک کی سطح' : 'Stock levels',
                  subtitle: LanguageController.isUrdu ? 'انوینٹری کی مقدار اور الرٹس' : 'Inventory quantity and alerts',
                  icon: Icons.warehouse_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        if (!_isEditing) ...[
                          Expanded(
                            child: AppFormTextField(
                              controller: _initialStockController,
                              labelText: LanguageController.isUrdu ? 'ابتدائی اسٹاک' : 'Initial Stock',
                              hintText: '0',
                              prefixIcon: Icons.inventory_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: AppFormTextField(
                            controller: _minimumStockController,
                            labelText: LanguageController.isUrdu ? 'کم از کم اسٹاک الرٹ' : 'Minimum Stock Alert',
                            hintText: '5',
                            prefixIcon: Icons.warning_amber_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FormSectionCard(
                  title: LanguageController.isUrdu ? 'تفصیل' : 'Description',
                  subtitle: LanguageController.isUrdu ? 'اختیاری پروڈکٹ نوٹس' : 'Optional product notes',
                  icon: Icons.notes_outlined,
                  children: [
                    AppFormTextField(
                      controller: _descriptionController,
                      labelText: LanguageController.isUrdu ? 'تفصیل / نوٹس' : 'Description / Notes',
                      hintText: LanguageController.isUrdu ? 'پروڈکٹ کی تفصیلات، اقسام وغیرہ۔' : 'Product details, variants, etc.',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveProduct(),
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