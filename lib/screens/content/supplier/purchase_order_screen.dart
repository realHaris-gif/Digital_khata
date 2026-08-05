import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/supplier_model.dart';
import '../../../models/supplier_cataloge_iteam.dart';
import 'package:digital_khata/services/supplier_service.dart';
import 'package:digital_khata/services/supplier_procurement_service.dart';
import 'package:digital_khata/services/supplier_payment_service.dart';
import 'package:digital_khata/services/notification_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class PurchaseOrderScreen extends ConsumerStatefulWidget {
  final Supplier? preselectedSupplier;

  const PurchaseOrderScreen({super.key, this.preselectedSupplier});

  @override
  ConsumerState<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {
  final _supabase = Supabase.instance.client;
  late final SupplierRepository _supplierRepo;
  late final SupplierProcurementService _procurementRepo;
  late final SupplierPaymentService _paymentService;
  final NotificationService _notificationService = NotificationService();

  Supplier? _selectedSupplier;
  List<Supplier> _suppliers = [];
  List<SupplierCatalogItem> _catalogItems = [];
  final List<Map<String, dynamic>> _selectedOrderItems = [];

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _successDetailsMessage;
  String? _notes;

  // Blue Palette Constants matching SuppliersScreen
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _supplierRepo = SupplierRepository(_supabase);
    _procurementRepo = SupplierProcurementService(_supabase);
    _paymentService = SupplierPaymentService(_supabase);
    
    // Handle preselected supplier reference matching safely
    if (widget.preselectedSupplier != null) {
      _selectedSupplier = widget.preselectedSupplier;
    }
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final suppliers = await _supplierRepo.getSuppliers(userId);
      setState(() {
        _suppliers = suppliers;
        if (_selectedSupplier == null && suppliers.isNotEmpty) {
          _selectedSupplier = suppliers.first;
        } else if (_selectedSupplier != null) {
          // Ensure we reference the exact object instance from the fetched list matching the ID
          try {
            _selectedSupplier = suppliers.firstWhere((s) => s.id == _selectedSupplier!.id);
          } catch (_) {
            _selectedSupplier = suppliers.isNotEmpty ? suppliers.first : null;
          }
        }
      });

      if (_selectedSupplier != null) {
        await _loadCatalog(_selectedSupplier!.id);
      }
    } catch (e) {
      debugPrint('Error loading PO data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCatalog(String supplierId) async {
    try {
      final items = await _procurementRepo.getSupplierCatalog(supplierId);
      setState(() {
        _catalogItems = items;
        _selectedOrderItems.clear();
      });
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    }
  }

  void _addItemToOrder(SupplierCatalogItem item) {
    setState(() {
      final index = _selectedOrderItems.indexWhere((element) => element['id'] == item.id);
      if (index >= 0) {
        _selectedOrderItems[index]['quantity'] += 1.0;
      } else {
        _selectedOrderItems.add({
          'id': item.id,
          'product_name': item.name,
          'quantity': 1.0,
          'unit_price': item.purchasePrice,
          'unit': item.unit,
        });
      }
    });
  }

  double get _subtotal {
    return _selectedOrderItems.fold(
        0.0, (sum, item) => sum + ((item['quantity'] as double) * (item['unit_price'] as double)));
  }

  Future<void> _promptForAccountAndPay() async {
    if (_selectedSupplier == null || _selectedOrderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageController.isUrdu 
                ? 'براہ کرم ایک سپلائر منتخب کریں اور اشیاء شامل کریں۔' 
                : 'Please select a supplier and add items.',
            textDirection: LanguageController.contentTextDirection,
          ),
        ),
      );
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    List<Map<String, dynamic>> accounts = [];
    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId);
      accounts = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
    }

    if (accounts.isEmpty) {
      accounts = [
        {'id': 'cash_default', 'name': LanguageController.isUrdu ? 'نقد اکاؤنٹ' : 'Cash Account', 'balance': 0.0},
        {'id': 'bank_default', 'name': LanguageController.isUrdu ? 'بینک اکاؤنٹ' : 'Bank Account', 'balance': 0.0},
      ];
    }

    String selectedAccountId = accounts.first['id'].toString();
    String selectedAccountName = accounts.first['name'].toString();
    final isDark = ThemeController.isDarkMode;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? spaceCadet : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Text(
                    LanguageController.isUrdu ? 'ادائیگی کا اکاؤنٹ منتخب کریں' : 'Select Payment Account',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : oxfordBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        final accId = acc['id'].toString();
                        final accName = acc['name'].toString();
                        final rawBal = acc['balance'] ?? acc['current_balance'] ?? 0;
                        final double accBalance = (rawBal as num).toDouble();

                        return Material(
                          color: Colors.transparent,
                          child: RadioListTile<String>(
                            title: Text(accName, textDirection: LanguageController.contentTextDirection, style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontWeight: FontWeight.bold)),
                            subtitle: Text('Balance: Rs. ${accBalance.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600)),
                            value: accId,
                            groupValue: selectedAccountId,
                            activeColor: isDark ? jordyBlue : yinMnBlue,
                            onChanged: (val) {
                              setModalState(() {
                                selectedAccountId = val!;
                                selectedAccountName = accName;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? jordyBlue : yinMnBlue,
                        foregroundColor: isDark ? oxfordBlue : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _completePurchaseOrderAndPay(selectedAccountId, selectedAccountName);
                      },
                      child: Text(
                        LanguageController.isUrdu ? 'تصدیق کریں اور ادائیگی کریں' : 'Confirm & Pay',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completePurchaseOrderAndPay(String accountId, String accountName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isProcessing = true);

    try {
      final invoiceRes = await _supabase.from('invoices').insert({
        'user_id': userId,
        'invoice_number': 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'status': 'Pending',
        'subtotal': _subtotal,
        'total': _subtotal,
        'notes': _notes ?? 'Purchase Order for Supplier: ${_selectedSupplier!.name}',
      }).select('id').single();

      final invoiceId = invoiceRes['id'] as String;

      for (var item in _selectedOrderItems) {
        await _supabase.from('invoice_items').insert({
          'invoice_id': invoiceId,
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'line_total': (item['quantity'] as double) * (item['unit_price'] as double),
        });
      }

      await _paymentService.paySupplier(
        userId: userId,
        supplierId: _selectedSupplier!.id,
        amount: _subtotal,
        paymentMethod: accountName,
        notes: 'Deducted from $accountName for PO-${invoiceId.substring(0, 5)}',
      );

      if (!accountId.contains('_default')) {
        try {
          final currentAcc = await _supabase.from('accounts').select('balance, current_balance').eq('id', accountId).single();
          final double currentBal = ((currentAcc['balance'] ?? currentAcc['current_balance']) as num).toDouble();
          
          await _supabase.from('accounts').update({
            'balance': currentBal - _subtotal,
            'current_balance': currentBal - _subtotal,
          }).eq('id', accountId);
        } catch (_) {}
      }

      await _procurementRepo.deliverPurchaseOrder(
        userId: userId,
        invoiceId: invoiceId,
        supplierId: _selectedSupplier!.id,
        orderedItems: _selectedOrderItems,
      );

      await _notificationService.notifyInvoiceCreated('PO-${invoiceId.substring(0, 5)}');
      
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': LanguageController.isUrdu ? 'رقم کی کٹوتی ہو گئی' : 'Amount Deducted',
        'message': LanguageController.isUrdu 
            ? 'پی او ادائیگی کے لیے $accountName سے Rs. ${_subtotal.toStringAsFixed(2)} کامیابی کے ساتھ کاٹ لیے گئے۔' 
            : 'Rs. ${_subtotal.toStringAsFixed(2)} successfully deducted from $accountName for PO payment.',
        'type': 'success',
        'category': 'transactions',
        'icon': 'payment',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _successDetailsMessage = LanguageController.isUrdu 
              ? '$accountName سے Rs. ${_subtotal.toStringAsFixed(2)} کاٹ لیے گئے اور اسٹاک کی اشیاء کامیابی کے ساتھ شامل کر دی گئیں۔' 
              : 'Rs. ${_subtotal.toStringAsFixed(2)} deducted from $accountName & stock items added successfully.';
        });
      }
    } catch (e) {
      debugPrint('Error completing PO payment and stock sync: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'آرڈر پر کارروائی کرنے میں ناکام: $e' : 'Failed to process order: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? spaceCadet : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: LanguageController.contentTextDirection,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LanguageController.isUrdu ? 'آرڈر اور ادائیگی کامیاب' : 'Order & Payment Successful',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : oxfordBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _successDetailsMessage ?? (LanguageController.isUrdu ? 'ادائیگی پروسیس ہو چکی ہے اور اسٹاک کی فہرست اپ ڈیٹ کر دی گئی ہے۔' : 'Payment has been processed and stock list updated.'),
              textAlign: TextAlign.center,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: oxfordBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.pop(true),
                child: Text(
                  LanguageController.isUrdu ? 'ہو گیا' : 'Done',
                  textDirection: LanguageController.contentTextDirection,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    // Safely verify if current _selectedSupplier matches an item in the list
    Supplier? dropdownValue;
    if (_selectedSupplier != null && _suppliers.isNotEmpty) {
      try {
        dropdownValue = _suppliers.firstWhere((s) => s.id == _selectedSupplier!.id);
      } catch (_) {
        dropdownValue = _suppliers.first;
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            LanguageController.isUrdu ? 'خریداری کا آرڈر بنائیں' : 'Create Purchase Order',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? spaceCadet : Colors.white,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: isDark ? jordyBlue : yinMnBlue),
        ),
        body: _isLoading
            ? _buildSkeletonLoadingState(isDark)
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    DropdownButtonFormField<Supplier>(
                      value: dropdownValue,
                      dropdownColor: isDark ? spaceCadet : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: LanguageController.isUrdu ? 'سپلائر منتخب کریں' : 'Select Supplier',
                        labelStyle: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                        filled: true,
                        fillColor: isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? jordyBlue : yinMnBlue, width: 1.5),
                        ),
                      ),
                      items: _suppliers.map((s) => DropdownMenuItem<Supplier>(
                            value: s,
                            child: Text(s.name, textDirection: LanguageController.contentTextDirection, style: TextStyle(color: isDark ? Colors.white : oxfordBlue)),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSupplier = val);
                          _loadCatalog(val.id);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LanguageController.isUrdu ? 'سپلائر کیٹلاگ پروڈکٹس' : 'Supplier Catalog Products',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : oxfordBlue),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 2,
                      child: _catalogItems.isEmpty
                          ? Center(
                              child: Text(
                                LanguageController.isUrdu ? 'سپلائر کیٹلاگ میں کوئی پروڈکٹ دستیاب نہیں ہے۔' : 'No products available in supplier catalog.',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _catalogItems.length,
                              itemBuilder: (context, index) {
                                final catalogItem = _catalogItems[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      title: Text(
                                        catalogItem.name,
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : oxfordBlue),
                                      ),
                                      subtitle: Text(
                                        'Price: Rs. ${catalogItem.purchasePrice.toStringAsFixed(2)} • Unit: ${catalogItem.unit}',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.add_circle_rounded, color: isDark ? jordyBlue : yinMnBlue),
                                        onPressed: () => _addItemToOrder(catalogItem),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 24),
                    Text(
                      LanguageController.isUrdu ? 'منتخب کردہ آرڈر کی اشیاء' : 'Selected Order Items',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : oxfordBlue),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 2,
                      child: _selectedOrderItems.isEmpty
                          ? Center(
                              child: Text(
                                LanguageController.isUrdu ? 'آرڈر میں ابھی تک کوئی شے شامل نہیں کی گئی۔' : 'No items added to order yet.',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _selectedOrderItems.length,
                              itemBuilder: (context, index) {
                                final orderItem = _selectedOrderItems[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      title: Text(
                                        orderItem['product_name'],
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : oxfordBlue),
                                      ),
                                      subtitle: Text(
                                        'Qty: ${orderItem['quantity']} x Rs. ${orderItem['unit_price']}',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                                      ),
                                      trailing: Text(
                                        'Rs. ${(orderItem['quantity'] * orderItem['unit_price']).toStringAsFixed(2)}',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? jordyBlue : yinMnBlue),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Text(
                            'Total: Rs. ${_subtotal.toStringAsFixed(2)}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : oxfordBlue),
                          ),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _promptForAccountAndPay,
                              icon: _isProcessing 
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: isDark ? oxfordBlue : Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.payment_rounded, size: 20),
                              label: Text(
                                _isProcessing 
                                    ? (LanguageController.isUrdu ? 'پروسیس ہو رہا ہے...' : 'Processing...') 
                                    : (LanguageController.isUrdu ? 'ادائیگی کریں اور اسٹاک میں شامل کریں' : 'Pay & Add to Stock'), 
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                backgroundColor: isDark ? jordyBlue : yinMnBlue,
                                foregroundColor: isDark ? oxfordBlue : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 72,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}