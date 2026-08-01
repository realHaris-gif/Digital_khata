import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          // Validate that the pre-selected category ID actually exists in fetched categories
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
          message: 'Error saving product: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      appBar: formAppBar(
        context,
        title: _isEditing ? 'Edit Product' : 'Add New Product',
        subtitle: _isEditing
            ? 'Update product details and pricing'
            : 'Add a product to your inventory',
      ),
      bottomBar: FormBottomBar(
        primaryLabel: _isEditing ? 'Update Product' : 'Save Product',
        primaryIcon: Icons.check_rounded,
        isLoading: _isLoading,
        onPrimary: _isLoading ? null : _saveProduct,
        secondaryLabel: 'Cancel',
        onSecondary: () => context.pop(),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                title: 'Product identity',
                subtitle: 'Name, category, and identifiers',
                icon: Icons.inventory_2_outlined,
                children: [
                  AppFormTextField(
                    controller: _nameController,
                    autofocus: true,
                    labelText: 'Product Name *',
                    hintText: 'e.g. Premium Tea 500g',
                    prefixIcon: Icons.shopping_bag_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter name'
                        : null,
                  ),
                  AppFormDropdown<String?>(
                    value: _selectedCategoryId,
                    labelText: 'Category',
                    hintText: 'Select a category (Optional)',
                    prefixIcon: Icons.category_outlined,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None / General'),
                      ),
                      ..._categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppFormTextField(
                          controller: _skuController,
                          labelText: 'SKU / Code',
                          hintText: 'SKU-001',
                          prefixIcon: Icons.tag_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppFormTextField(
                          controller: _unitController,
                          labelText: 'Unit',
                          hintText: 'pcs, kg, box',
                          prefixIcon: Icons.straighten_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  AppFormTextField(
                    controller: _barcodeController,
                    labelText: 'Barcode Number',
                    hintText: 'Scan or type barcode',
                    prefixIcon: Icons.qr_code_2_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Pricing',
                subtitle: 'Purchase and selling rates',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppFormTextField(
                          controller: _purchasePriceController,
                          labelText: 'Purchase Price (Rs.)',
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
                          labelText: 'Selling Price (Rs.) *',
                          hintText: '0.00',
                          prefixIcon: Icons.sell_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.next,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Enter price'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Stock levels',
                subtitle: 'Inventory quantity and alerts',
                icon: Icons.warehouse_outlined,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isEditing) ...[
                        Expanded(
                          child: AppFormTextField(
                            controller: _initialStockController,
                            labelText: 'Initial Stock',
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
                          labelText: 'Minimum Stock Alert',
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
                title: 'Description',
                subtitle: 'Optional product notes',
                icon: Icons.notes_outlined,
                children: [
                  AppFormTextField(
                    controller: _descriptionController,
                    labelText: 'Description / Notes',
                    hintText: 'Product details, variants, etc.',
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
    );
  }
}
