import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:digital_khata/services/inventory_service.dart';

class InvoiceRepository {
  final SupabaseClient _supabase;
  final InventoryRepository _inventoryRepo;

  InvoiceRepository(this._supabase)
      : _inventoryRepo = InventoryRepository(_supabase);

  // =========================================================
  // INVOICE NUMBER GENERATOR
  // =========================================================
  Future<String> generateNextInvoiceNumber(String userId) async {
    final response = await _supabase
        .from('invoices')
        .select('invoice_number')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if ((response as List).isEmpty) {
      return 'INV-0001';
    }

    final lastNumberStr = response.first['invoice_number'] as String;
    final match = RegExp(r'INV-(\d+)').firstMatch(lastNumberStr);

    if (match != null) {
      final lastNum = int.tryParse(match.group(1) ?? '0') ?? 0;
      final nextNum = lastNum + 1;
      return 'INV-${nextNum.toString().padLeft(4, '0')}';
    }

    return 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  // =========================================================
  // GET INVOICES WITH FILTERS & SEARCH
  // =========================================================
  Future<List<Invoice>> getInvoices({
    required String userId,
    String? searchQuery,
    InvoiceStatus? status,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('invoices')
        .select('*, customers(name), invoice_items(*), invoice_payments(*)')
        .eq('user_id', userId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('invoice_number.ilike.$term,notes.ilike.$term');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final List list = response as List;
    return list.map((json) {
      final itemJsonList = json['invoice_items'] as List? ?? [];
      final paymentJsonList = json['invoice_payments'] as List? ?? [];

      final items = itemJsonList.map((i) => InvoiceItem.fromJson(i)).toList();
      final payments =
          paymentJsonList.map((p) => InvoicePayment.fromJson(p)).toList();

      return Invoice.fromJson(json, items: items, payments: payments);
    }).toList();
  }

  // =========================================================
  // GET SINGLE INVOICE BY ID
  // =========================================================
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    final response = await _supabase
        .from('invoices')
        .select('*, customers(name), invoice_items(*), invoice_payments(*)')
        .eq('id', invoiceId)
        .maybeSingle();

    if (response == null) return null;

    final itemJsonList = response['invoice_items'] as List? ?? [];
    final paymentJsonList = response['invoice_payments'] as List? ?? [];

    final items = itemJsonList.map((i) => InvoiceItem.fromJson(i)).toList();
    final payments =
        paymentJsonList.map((p) => InvoicePayment.fromJson(p)).toList();

    return Invoice.fromJson(response, items: items, payments: payments);
  }

  // =========================================================
  // CREATE INVOICE
  // =========================================================
  Future<Invoice> createInvoice({
    required String userId,
    String? customerId,
    required String invoiceNumber,
    InvoiceStatus status = InvoiceStatus.draft,
    required double subtotal,
    double discount = 0.0,
    String discountType = 'flat',
    double tax = 0.0,
    String taxType = 'flat',
    double shipping = 0.0,
    required double total,
    String? notes,
    required List<InvoiceItem> items,
  }) async {
    // 1. Insert Invoices Header
    final invoiceResponse = await _supabase
        .from('invoices')
        .insert({
          'user_id': userId,
          'customer_id': customerId,
          'invoice_number': invoiceNumber,
          'status': status.value,
          'subtotal': subtotal,
          'discount': discount,
          'discount_type': discountType,
          'tax': tax,
          'tax_type': taxType,
          'shipping': shipping,
          'total': total,
          'notes': notes,
        })
        .select('*, customers(name)')
        .single();

    final String createdInvoiceId = invoiceResponse['id'];

    // 2. Insert Invoice Line Items
    final List<InvoiceItem> insertedItems = [];
    if (items.isNotEmpty) {
      final itemPayloads = items
          .map((item) => {
                'invoice_id': createdInvoiceId,
                'product_id': item.productId,
                'product_name': item.productName,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'discount': item.discount,
                'tax': item.tax,
                'line_total': item.lineTotal,
              })
          .toList();

      final itemsResponse = await _supabase
          .from('invoice_items')
          .insert(itemPayloads)
          .select();

      insertedItems.addAll(
          (itemsResponse as List).map((i) => InvoiceItem.fromJson(i)).toList());
    }

    final newInvoice = Invoice.fromJson(
      invoiceResponse,
      items: insertedItems,
      payments: const [],
    );

    // 3. Handle Initial Paid Status Stock Deduction & Customer Ledger
    if (status == InvoiceStatus.paid) {
      await _processStockDeduction(userId, newInvoice);
    }

    return newInvoice;
  }

  // =========================================================
  // EDIT / UPDATE INVOICE
  // =========================================================
  Future<Invoice> updateInvoice({
    required String invoiceId,
    required String userId,
    String? customerId,
    required String invoiceNumber,
    required InvoiceStatus status,
    required double subtotal,
    required double discount,
    required String discountType,
    required double tax,
    required String taxType,
    required double shipping,
    required double total,
    String? notes,
    required List<InvoiceItem> items,
  }) async {
    final oldInvoice = await getInvoiceById(invoiceId);

    // 1. Update Header
    final response = await _supabase
        .from('invoices')
        .update({
          'customer_id': customerId,
          'invoice_number': invoiceNumber,
          'status': status.value,
          'subtotal': subtotal,
          'discount': discount,
          'discount_type': discountType,
          'tax': tax,
          'tax_type': taxType,
          'shipping': shipping,
          'total': total,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invoiceId)
        .select('*, customers(name)')
        .single();

    // 2. Refresh Line Items (Delete & Re-insert)
    await _supabase.from('invoice_items').delete().eq('invoice_id', invoiceId);

    final List<InvoiceItem> updatedItems = [];
    if (items.isNotEmpty) {
      final itemPayloads = items
          .map((item) => {
                'invoice_id': invoiceId,
                'product_id': item.productId,
                'product_name': item.productName,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'discount': item.discount,
                'tax': item.tax,
                'line_total': item.lineTotal,
              })
          .toList();

      final itemsResponse = await _supabase
          .from('invoice_items')
          .insert(itemPayloads)
          .select();

      updatedItems.addAll(
          (itemsResponse as List).map((i) => InvoiceItem.fromJson(i)).toList());
    }

    final updatedInvoice = Invoice.fromJson(
      response,
      items: updatedItems,
      payments: oldInvoice?.payments ?? [],
    );

    // 3. Handle Status Changes (Stock Restoration vs Stock Deduction)
    if (oldInvoice != null) {
      if (oldInvoice.status != InvoiceStatus.paid &&
          status == InvoiceStatus.paid) {
        await _processStockDeduction(userId, updatedInvoice);
      } else if (oldInvoice.status == InvoiceStatus.paid &&
          status == InvoiceStatus.cancelled) {
        await _processStockRestoration(userId, updatedInvoice);
      }
    }

    return updatedInvoice;
  }

  // =========================================================
  // RECORD PAYMENT
  // =========================================================
  Future<InvoicePayment> recordPayment({
    required String invoiceId,
    required String userId,
    String? accountId,
    required double amount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    // 1. Insert Payment Record
    final response = await _supabase
        .from('invoice_payments')
        .insert({
          'invoice_id': invoiceId,
          'account_id': accountId,
          'amount': amount,
          'payment_method': paymentMethod,
          'payment_date': paymentDate.toIso8601String(),
          'notes': notes,
        })
        .select()
        .single();

    final payment = InvoicePayment.fromJson(response);

    // 2. Recalculate Invoice Status (Paid vs Partially Paid)
    final invoice = await getInvoiceById(invoiceId);
    if (invoice != null) {
      final double totalPaid = invoice.totalPaid;
      InvoiceStatus newStatus = invoice.status;

      if (totalPaid >= invoice.total) {
        newStatus = InvoiceStatus.paid;
      } else if (totalPaid > 0) {
        newStatus = InvoiceStatus.partiallyPaid;
      }

      await _supabase
          .from('invoices')
          .update({'status': newStatus.value})
          .eq('id', invoiceId);

      // Trigger Stock Deduction if status moved to Paid
      if (invoice.status != InvoiceStatus.paid &&
          newStatus == InvoiceStatus.paid) {
        await _processStockDeduction(userId, invoice);
      }
    }

    return payment;
  }

  // =========================================================
  // DUPLICATE INVOICE
  // =========================================================
  Future<Invoice> duplicateInvoice(String invoiceId, String userId) async {
    final original = await getInvoiceById(invoiceId);
    if (original == null) throw Exception('Original invoice not found');

    final nextNumber = await generateNextInvoiceNumber(userId);

    return createInvoice(
      userId: userId,
      customerId: original.customerId,
      invoiceNumber: nextNumber,
      status: InvoiceStatus.draft,
      subtotal: original.subtotal,
      discount: original.discount,
      discountType: original.discountType,
      tax: original.tax,
      taxType: original.taxType,
      shipping: original.shipping,
      total: original.total,
      notes: original.notes != null ? '${original.notes} (Copy)' : 'Duplicated Invoice',
      items: original.items,
    );
  }

  // =========================================================
  // DELETE INVOICE
  // =========================================================
  Future<void> deleteInvoice(String invoiceId) async {
    await _supabase.from('invoices').delete().eq('id', invoiceId);
  }

  // =========================================================
  // PRIVATE STOCK DEDUCTION / RESTORATION HELPERS
  // =========================================================
  Future<void> _processStockDeduction(String userId, Invoice invoice) async {
    for (final item in invoice.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        await _inventoryRepo.recordStockMovement(
          userId: userId,
          productId: item.productId!,
          type: StockMovementType.outStock,
          quantity: item.quantity,
          reference: invoice.invoiceNumber,
          notes: 'Invoice #${invoice.invoiceNumber} Paid',
        );
      }
    }
  }

  Future<void> _processStockRestoration(String userId, Invoice invoice) async {
    for (final item in invoice.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        await _inventoryRepo.recordStockMovement(
          userId: userId,
          productId: item.productId!,
          type: StockMovementType.inStock,
          quantity: item.quantity,
          reference: invoice.invoiceNumber,
          notes: 'Invoice #${invoice.invoiceNumber} Cancelled (Restored Stock)',
        );
      }
    }
  }
}