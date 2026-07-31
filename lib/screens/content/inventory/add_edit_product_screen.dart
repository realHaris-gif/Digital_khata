import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';

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

    final repo = ref.read(inventoryRepoProvider);
    final list = await repo.getCategories(userId);
    if (mounted) {
      setState(() {
        _categories = list;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategoryId = val);
                },
              ),
              const SizedBox(height: 16),

              // Prices Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price (Rs.)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Selling Price (Rs.) *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter price'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Initial Stock (Only for new products) & Minimum Stock
              Row(
                children: [
                  if (!_isEditing) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _initialStockController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Initial Stock',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: TextFormField(
                      controller: _minimumStockController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Minimum Stock Alert',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SKU & Unit Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU / Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit (e.g. pcs, kg, box)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barcode Input
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode Number',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description / Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Product' : 'Save Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}