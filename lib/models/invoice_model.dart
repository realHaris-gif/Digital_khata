import 'package:equatable/equatable.dart';

enum InvoiceStatus {
  draft,
  pending,
  paid,
  partiallyPaid,
  cancelled;

  String get value {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static InvoiceStatus fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'pending':
        return InvoiceStatus.pending;
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially paid':
      case 'partiallypaid':
        return InvoiceStatus.partiallyPaid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }
}

class InvoiceItem extends Equatable {
  final String id;
  final String invoiceId;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final double lineTotal;
  final DateTime createdAt;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.lineTotal,
    required this.createdAt,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? 'Custom Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'invoice_id': invoiceId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': discount,
        'tax': tax,
        'line_total': lineTotal,
      };

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? tax,
    double? lineTotal,
    DateTime? createdAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        productId,
        productName,
        quantity,
        unitPrice,
        discount,
        tax,
        lineTotal,
        createdAt,
      ];
}

class InvoicePayment extends Equatable {
  final String id;
  final String invoiceId;
  final String? accountId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    this.accountId,
    required this.amount,
    this.paymentMethod = 'Cash',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: json['id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? '',
      accountId: json['account_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'invoice_id': invoiceId,
        'account_id': accountId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_date': paymentDate.toIso8601String(),
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        accountId,
        amount,
        paymentMethod,
        paymentDate,
        notes,
        createdAt,
      ];
}

class Invoice extends Equatable {
  final String id;
  final String userId;
  final String? customerId;
  final String? customerName;
  final String invoiceNumber;
  final InvoiceStatus status;
  final double subtotal;
  final double discount;
  final String discountType; // flat, percentage
  final double tax;
  final String taxType; // flat, percentage
  final double shipping;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  const Invoice({
    required this.id,
    required this.userId,
    this.customerId,
    this.customerName,
    required this.invoiceNumber,
    this.status = InvoiceStatus.draft,
    required this.subtotal,
    this.discount = 0.0,
    this.discountType = 'flat',
    this.tax = 0.0,
    this.taxType = 'flat',
    this.shipping = 0.0,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.payments = const [],
  });

  double get totalPaid =>
      payments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get remainingBalance => (total - totalPaid).clamp(0.0, double.infinity);

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    List<InvoiceItem> items = const [],
    List<InvoicePayment> payments = const [],
  }) {
    // Check if customer name exists from joined 'people' table
    // Check if customer name exists from joined 'customers' table
// Check joined customer name from 'customers'
String? resolvedCustomerName;
if (json['customers'] != null && json['customers'] is Map) {
  resolvedCustomerName = json['customers']['name'] as String?;
} else if (json['people'] != null && json['people'] is Map) {
  resolvedCustomerName = json['people']['name'] as String?;
}

    return Invoice(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      customerName: resolvedCustomerName,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      status: InvoiceStatus.fromString(json['status'] as String? ?? 'Draft'),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'flat',
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      taxType: json['tax_type'] as String? ?? 'flat',
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      items: items,
      payments: payments,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
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
      };

  Invoice copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? customerName,
    String? invoiceNumber,
    InvoiceStatus? status,
    double? subtotal,
    double? discount,
    String? discountType,
    double? tax,
    String? taxType,
    double? shipping,
    double? total,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem>? items,
    List<InvoicePayment>? payments,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tax: tax ?? this.tax,
      taxType: taxType ?? this.taxType,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      payments: payments ?? this.payments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        customerId,
        customerName,
        invoiceNumber,
        status,
        subtotal,
        discount,
        discountType,
        tax,
        taxType,
        shipping,
        total,
        notes,
        createdAt,
        updatedAt,
        items,
        payments,
      ];
}