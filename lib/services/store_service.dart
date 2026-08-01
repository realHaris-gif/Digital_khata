import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/store_model.dart';

class StoreService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser?.id ?? '';

  // ---------------------------------------------------------
  // STORE SETUP & MANAGEMENT
  // ---------------------------------------------------------

  Future<StoreModel?> getMyStore() async {
    if (_userId.isEmpty) return null;
    final res = await _client
        .from('stores')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (res == null) return null;
    return StoreModel.fromJson(res);
  }

  Future<String?> uploadBrandingImage(File file, String path) async {
    await _client.storage.from('store_branding').upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('store_branding').getPublicUrl(path);
  }

  Future<StoreModel> saveStore({
    required String storeName,
    required String slug,
    String? description,
    String? phone,
    String? email,
    String? address,
    File? logoFile,
    File? bannerFile,
    String? currentLogoUrl,
    String? currentBannerUrl,
    String themeColor = '#FF7A00',
  }) async {
    String? logoUrl = currentLogoUrl;
    String? bannerUrl = currentBannerUrl;

    if (logoFile != null) {
      logoUrl = await uploadBrandingImage(logoFile, 'logos/$_userId-logo.jpg');
    }
    if (bannerFile != null) {
      bannerUrl = await uploadBrandingImage(bannerFile, 'banners/$_userId-banner.jpg');
    }

    final existing = await getMyStore();

    final payload = {
      'user_id': _userId,
      'store_name': storeName,
      'slug': slug.toLowerCase().replaceAll(' ', '-'),
      'description': description,
      'phone': phone,
      'email': email,
      'address': address,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'theme_color': themeColor,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing != null) {
      final res = await _client
          .from('stores')
          .update(payload)
          .eq('id', existing.id)
          .select()
          .single();
      return StoreModel.fromJson(res);
    } else {
      payload['created_at'] = DateTime.now().toIso8601String();
      final res = await _client.from('stores').insert(payload).select().single();
      return StoreModel.fromJson(res);
    }
  }

  // ---------------------------------------------------------
  // ORDER PROCESSING & INVENTORY DEDUCTION
  // ---------------------------------------------------------

  Future<List<OrderModel>> getStoreOrders(String storeId) async {
    final res = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);

    return (res as List).map((o) {
      final items = (o['order_items'] as List? ?? [])
          .map((i) => OrderItemModel.fromJson(i))
          .toList();
      return OrderModel.fromJson(o, items: items);
    }).toList();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, List<OrderItemModel> items) async {
    await _client.from('orders').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    // If order is confirmed or delivered, deduct product stock
    if (status == OrderStatus.confirmed || status == OrderStatus.delivered) {
      for (var item in items) {
        if (item.productId != null) {
          final prodRes = await _client
              .from('products')
              .select('current_stock')
              .eq('id', item.productId!)
              .maybeSingle();

          if (prodRes != null) {
            final currentStock = (prodRes['current_stock'] as num).toDouble();
            final updatedStock = (currentStock - item.quantity).clamp(0.0, double.infinity);
            await _client
                .from('products')
                .update({'current_stock': updatedStock})
                .eq('id', item.productId!);
          }
        }
      }
    }
  }

  Future<OrderModel> placeOrder({
    required String storeId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String paymentMethod,
    required List<StoreCartItem> cartItems,
    String? notes,
  }) async {
    final subtotal = cartItems.fold(0.0, (s, item) => s + item.lineTotal);
    const shipping = 0.0;
    final total = subtotal + shipping;

    // 1. Insert Order Header
    final orderRes = await _client.from('orders').insert({
      'store_id': storeId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'notes': notes,
      'status': 'pending',
    }).select().single();

    final orderId = orderRes['id'] as String;

    // 2. Insert Order Items
    final List<Map<String, dynamic>> itemsPayload = cartItems.map((item) {
      return {
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'line_total': item.lineTotal,
      };
    }).toList();

    await _client.from('order_items').insert(itemsPayload);

    return OrderModel.fromJson(orderRes);
  }

  // ---------------------------------------------------------
  // WHATSAPP ORDERING INTEGRATION
  // ---------------------------------------------------------

  Future<void> sendWhatsAppOrder({
    required String storePhone,
    required String customerName,
    required String customerPhone,
    required String address,
    required List<StoreCartItem> cartItems,
    required double total,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *NEW ONLINE ORDER*');
    buffer.writeln('👤 *Customer:* $customerName');
    buffer.writeln('📞 *Phone:* $customerPhone');
    buffer.writeln('📍 *Address:* $address\n');
    buffer.writeln('📦 *Items:*');

    for (var item in cartItems) {
      buffer.writeln('• ${item.productName} x${item.quantity} = Rs. ${item.lineTotal.toStringAsFixed(0)}');
    }

    buffer.writeln('\n💰 *Grand Total:* Rs. ${total.toStringAsFixed(0)}');

    final cleanPhone = storePhone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(buffer.toString())}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}