import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

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

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

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
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? spaceCadet : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  LanguageController.isUrdu ? 'آپ کی کارٹ' : 'Your Cart',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                const SizedBox(height: 12),
                ..._cart.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.productName,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        LanguageController.isUrdu ? 'مقدار: ${item.quantity}' : 'Qty: ${item.quantity}',
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600),
                      ),
                      trailing: Text(
                        'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: isDark ? jordyBlue : yinMnBlue, fontWeight: FontWeight.bold),
                      ),
                    )),
                const Divider(),
                const SizedBox(height: 8),
                _buildCheckoutTextField(nameCtrl, LanguageController.isUrdu ? 'آپ کا نام *' : 'Your Name *', isDark),
                const SizedBox(height: 12),
                _buildCheckoutTextField(phoneCtrl, LanguageController.isUrdu ? 'فون نمبر *' : 'Phone Number *', isDark, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildCheckoutTextField(addressCtrl, LanguageController.isUrdu ? 'ڈیلیوری کا پتہ *' : 'Delivery Address *', isDark),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? jordyBlue : yinMnBlue,
                    foregroundColor: isDark ? oxfordBlue : Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Text(
                    LanguageController.isUrdu ? 'آرڈر کی تصدیق کریں (واٹس ایپ)' : 'Confirm Order (WhatsApp)',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutTextField(TextEditingController controller, String label, bool isDark, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: LanguageController.contentTextDirection,
      style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? jordyBlue : yinMnBlue, fontSize: 13),
        filled: true,
        fillColor: isDark ? oxfordBlue.withOpacity(0.5) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? jordyBlue : yinMnBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    if (_isLoading) {
      return Theme(
        data: Theme.of(context).copyWith(scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC)),
        child: Scaffold(
          backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
          body: _buildSkeletonLoadingState(isDark),
        ),
      );
    }

    if (_store == null) {
      return Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        body: Center(
          child: Text(
            LanguageController.isUrdu ? 'اسٹور نہیں ملا۔' : 'Store not found.',
            textDirection: LanguageController.contentTextDirection,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? spaceCadet : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _store!.storeName,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : oxfordBlue),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _products.length,
                itemBuilder: (context, idx) {
                  final p = _products[idx];
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? jordyBlue.withOpacity(0.15) : lavender),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? oxfordBlue : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(Icons.inventory_2_rounded, size: 36, color: isDark ? jordyBlue : yinMnBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : oxfordBlue),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${p.sellingPrice.toStringAsFixed(0)}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? lavender : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(p),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? jordyBlue : yinMnBlue,
                                foregroundColor: isDark ? oxfordBlue : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                LanguageController.isUrdu ? 'کارٹ میں شامل کریں' : 'Add to Cart',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
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
                color: isDark ? spaceCadet : Colors.white,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? jordyBlue : yinMnBlue,
                    foregroundColor: isDark ? oxfordBlue : Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showCartModal,
                  child: Text(
                    LanguageController.isUrdu ? 'کارٹ دیکھیں (${_cart.length} آئٹمز)' : 'View Cart (${_cart.length} items)',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // Skeleton Shimmer Loading State
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? jordyBlue.withOpacity(0.1) : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 10),
                  Container(width: 100, height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Container(width: 60, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Container(width: double.infinity, height: 32, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(10))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}