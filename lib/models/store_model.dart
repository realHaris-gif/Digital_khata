import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  packed,
  shipped,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

class StoreModel extends Equatable {
  final String id;
  final String userId;
  final String storeName;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phone;
  final String? email;
  final String? address;
  final String themeColor;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreModel({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phone,
    this.email,
    this.address,
    this.themeColor = '#FF7A00',
    this.currency = 'PKR',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      themeColor: json['theme_color'] as String? ?? '#FF7A00',
      currency: json['currency'] as String? ?? 'PKR',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'store_name': storeName,
        'slug': slug,
        'description': description,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'phone': phone,
        'email': email,
        'address': address,
        'theme_color': themeColor,
        'currency': currency,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        storeName,
        slug,
        description,
        logoUrl,
        bannerUrl,
        phone,
        email,
        address,
        themeColor,
        currency,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class OrderItemModel extends Equatable {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double lineTotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': discount,
        'line_total': lineTotal,
      };

  @override
  List<Object?> get props =>
      [id, orderId, productId, productName, quantity, unitPrice, discount, lineTotal];
}

class OrderModel extends Equatable {
  final String id;
  final String storeId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.storeId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.status = OrderStatus.pending,
    required this.subtotal,
    this.discount = 0.0,
    this.shipping = 0.0,
    this.tax = 0.0,
    required this.total,
    this.paymentMethod = 'Cash on Delivery',
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<OrderItemModel> items = const []}) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Guest Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerAddress: json['customer_address'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Cash on Delivery',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'store_id': storeId,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'status': status.name,
        'subtotal': subtotal,
        'discount': discount,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        storeId,
        customerId,
        customerName,
        customerPhone,
        customerAddress,
        status,
        subtotal,
        discount,
        shipping,
        tax,
        total,
        paymentMethod,
        notes,
        createdAt,
        items,
      ];
}

class StoreCartItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  const StoreCartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  double get lineTotal => unitPrice * quantity;

  StoreCartItem copyWith({int? quantity}) {
    return StoreCartItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  @override
  List<Object?> get props => [productId, productName, unitPrice, quantity, imageUrl];
}