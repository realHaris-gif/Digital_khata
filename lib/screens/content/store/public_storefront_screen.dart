import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';

// Riverpod Provider for StoreService
final storeServiceProvider = Provider<StoreService>((ref) => StoreService());

class PublicStorefrontScreen extends ConsumerStatefulWidget {
  final String storeSlug;

  const PublicStorefrontScreen({super.key, required this.storeSlug});

  @override
  ConsumerState<PublicStorefrontScreen> createState() => _PublicStorefrontScreenState();
}

class _PublicStorefrontScreenState extends ConsumerState<PublicStorefrontScreen> {
  StoreModel? _store;
  List<Product> _products = [];
  final List<StoreCartItem> _cart = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicStore();
  }

  Future<void> _loadPublicStore() async {
    final client = Supabase.instance.client;
    final storeRes = await client
        .from('stores')
        .select()
        .eq('slug', widget.storeSlug)
        .maybeSingle();

    if (storeRes != null) {
      _store = StoreModel.fromJson(storeRes);

      final prodRes = await client
          .from('products')
          .select()
          .eq('user_id', _store!.userId);

      _products = (prodRes as List).map((p) => Product.fromJson(p)).toList();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _addToCart(Product p) {
    setState(() {
      final idx = _cart.indexWhere((item) => item.productId == p.id);
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
      } else {
        _cart.add(StoreCartItem(
          productId: p.id,
          productName: p.name,
          unitPrice: p.sellingPrice,
          quantity: 1,
        ));
      }
    });
  }

  void _showCartModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                ..._cart.map((item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text('Rs. ${item.lineTotal.toStringAsFixed(0)}'),
                    )),
                const Divider(),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Name *')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number *')),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Delivery Address *')),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || _store == null) return;

                    final service = ref.read(storeServiceProvider);
                    final total = _cart.fold(0.0, (s, i) => s + i.lineTotal);

                    await service.placeOrder(
                      storeId: _store!.id,
                      customerName: nameCtrl.text.trim(),
                      customerPhone: phoneCtrl.text.trim(),
                      customerAddress: addressCtrl.text.trim(),
                      paymentMethod: 'Cash on Delivery',
                      cartItems: _cart,
                    );

                    if (_store!.phone != null && _store!.phone!.isNotEmpty) {
                      await service.sendWhatsAppOrder(
                        storePhone: _store!.phone!,
                        customerName: nameCtrl.text.trim(),
                        customerPhone: phoneCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        cartItems: _cart,
                        total: total,
                      );
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() => _cart.clear());
                  },
                  child: const Text('Confirm Order (WhatsApp)', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_store == null) return const Scaffold(body: Center(child: Text('Store not found.')));

    return Scaffold(
      appBar: AppBar(title: Text(_store!.storeName), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _products.length,
              itemBuilder: (context, idx) {
                final p = _products[idx];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey.shade100,
                            child: const Center(child: Icon(Icons.inventory_2, size: 40, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rs. ${p.sellingPrice.toStringAsFixed(0)}'),
                        ElevatedButton(
                          onPressed: () => _addToCart(p),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00)),
                          child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00)),
                onPressed: _showCartModal,
                child: Text('View Cart (${_cart.length} items)', style: const TextStyle(color: Colors.white)),
              ),
            )
          : null,
    );
  }
}