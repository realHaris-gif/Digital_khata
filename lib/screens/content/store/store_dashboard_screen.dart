import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import 'store_settings_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

final storeServiceProvider = Provider((ref) => StoreService());

final myStoreProvider = FutureProvider<StoreModel?>((ref) {
  return ref.watch(storeServiceProvider).getMyStore();
});

final storeOrdersProvider = FutureProvider.family<List<OrderModel>, String>((ref, storeId) {
  return ref.watch(storeServiceProvider).getStoreOrders(storeId);
});

class StoreDashboardScreen extends ConsumerWidget {
  const StoreDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeController.isDarkMode;
    final storeAsync = ref.watch(myStoreProvider);

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.yinMnBlue),
          scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(
              LanguageController.isUrdu ? 'ڈیجیٹل اسٹور' : 'Digital Store',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
              ),
            ),
            centerTitle: true,
          ),
          body: storeAsync.when(
            data: (store) {
              if (store == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Icon(Icons.storefront_rounded, size: 72, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          LanguageController.isUrdu ? 'اپنا ڈیجیٹل اسٹور بنائیں' : 'Create Your Digital Store',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.oxfordBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          LanguageController.isUrdu ? 'سیکنڈوں میں آن لائن اسٹور فرنٹ سیٹ اپ کریں اور براہ راست واٹس ایپ یا ایپ پر آرڈر لیں۔' : 'Setup an online storefront in seconds and take orders directly on WhatsApp or in-app.',
                          textAlign: TextAlign.center,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                            foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StoreSettingsScreen()),
                            );
                            ref.invalidate(myStoreProvider);
                          },
                          icon: const Icon(Icons.add_business_rounded),
                          label: Text(
                            LanguageController.isUrdu ? 'ابھی اسٹور سیٹ اپ کریں' : 'Setup Store Now',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final ordersAsync = ref.watch(storeOrdersProvider(store.id));

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myStoreProvider);
                  ref.invalidate(storeOrdersProvider(store.id));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      // Store Link Banner Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.spaceCadet, AppColors.yinMnBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.spaceCadet.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.jordyBlue,
                              backgroundImage: store.logoUrl != null ? NetworkImage(store.logoUrl!) : null,
                              child: store.logoUrl == null
                                  ? const Icon(Icons.store_rounded, color: AppColors.oxfordBlue)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    store.storeName,
                                    textDirection: LanguageController.contentTextDirection,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'digitalkhata.app/store/${store.slug}',
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(color: AppColors.jordyBlue, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: Colors.white),
                              onPressed: () {
                                Share.share('Check out my digital store: https://digitalkhata.app/store/${store.slug}');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Orders Overview Metrics
                      ordersAsync.when(
                        data: (orders) {
                          final totalRevenue = orders
                              .where((o) => o.status == OrderStatus.delivered)
                              .fold(0.0, (sum, o) => sum + o.total);
                          final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.35,
                                children: [
                                  _buildMetricCard(
                                    title: LanguageController.isUrdu ? 'آن لائن آمدنی' : 'Online Revenue',
                                    value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                                    icon: Icons.payments_rounded,
                                    color: Colors.green.shade600,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    title: LanguageController.isUrdu ? 'زیر التوا آرڈرز' : 'Pending Orders',
                                    value: '$pendingCount',
                                    icon: Icons.pending_actions_rounded,
                                    color: Colors.amber.shade700,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    title: LanguageController.isUrdu ? 'کل آرڈرز' : 'Total Orders',
                                    value: '${orders.length}',
                                    icon: Icons.shopping_bag_rounded,
                                    color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    title: LanguageController.isUrdu ? 'ڈلیور ہو گیا' : 'Delivered',
                                    value: '${orders.where((o) => o.status == OrderStatus.delivered).length}',
                                    icon: Icons.local_shipping_rounded,
                                    color: Colors.teal.shade600,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // High-Visibility Management Actions (Stock & Settings)
                              Row(
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                        foregroundColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.xl),
                                          side: BorderSide(
                                            color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.25) : AppColors.lavender,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () => context.push('/inventory/products'),
                                      icon: const Icon(Icons.inventory_2_outlined, size: 20),
                                      label: Text(
                                        LanguageController.isUrdu ? 'اسٹاک کا نظم کریں' : 'Manage Stock',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                        foregroundColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.xl),
                                          side: BorderSide(
                                            color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.25) : AppColors.lavender,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => StoreSettingsScreen(store: store)),
                                        );
                                        ref.invalidate(myStoreProvider);
                                      },
                                      icon: const Icon(Icons.settings_outlined, size: 20),
                                      label: Text(
                                        LanguageController.isUrdu ? 'اسٹور کی ترتیبات' : 'Store Settings',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              Text(
                                LanguageController.isUrdu ? 'حالیہ گاہک کے آرڈرز' : 'Recent Customer Orders',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.oxfordBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              if (orders.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      LanguageController.isUrdu ? 'ابھی تک کوئی آن لائن آرڈر موصول نہیں ہوا۔' : 'No online orders received yet.',
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: orders.length,
                                  itemBuilder: (context, idx) {
                                    final order = orders[idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                        border: Border.all(
                                          color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                                        title: Text(
                                          order.customerName,
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue),
                                        ),
                                        subtitle: Text(
                                          '${order.items.length} items • ${order.paymentMethod}\n${order.customerPhone}',
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600, fontSize: 12),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          textDirection: LanguageController.contentTextDirection,
                                          children: [
                                            Text(
                                              'Rs. ${order.total.toStringAsFixed(0)}',
                                              textDirection: TextDirection.ltr,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue),
                                            ),
                                            const SizedBox(height: 4),
                                            _buildStatusBadge(order.status),
                                          ],
                                        ),
                                        onTap: () => _showOrderDetailsModal(context, ref, order, store.id),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                        loading: () => _buildOrdersSkeletonLoader(isDark),
                        error: (e, _) => Center(
                          child: Text(
                            LanguageController.isUrdu ? 'آرڈرز لوڈ کرنے میں خرابی: $e' : 'Error loading orders: $e',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => _buildStoreSkeletonLoader(isDark),
            error: (e, _) => Center(
              child: Text(
                LanguageController.isUrdu ? 'خرابی: $e' : 'Error: $e',
                textDirection: LanguageController.contentTextDirection,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Text(
                title, 
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.amber.shade800;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue.shade600;
        break;
      case OrderStatus.delivered:
        color = Colors.green.shade600;
        break;
      case OrderStatus.cancelled:
        color = Colors.red.shade600;
        break;
      default:
        color = Colors.purple.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.displayName,
        textDirection: LanguageController.contentTextDirection,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOrderDetailsModal(BuildContext context, WidgetRef ref, OrderModel order, String storeId) {
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Text(
                LanguageController.isUrdu ? 'آرڈر کی تفصیلات (${order.customerName})' : 'Order Details (${order.customerName})',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.oxfordBlue),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                LanguageController.isUrdu ? 'پتہ: ${order.customerAddress}' : 'Address: ${order.customerAddress}',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade700, fontSize: 13),
              ),
              Text(
                LanguageController.isUrdu ? 'فون: ${order.customerPhone}' : 'Phone: ${order.customerPhone}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade700, fontSize: 13),
              ),
              const Divider(height: 24),
              Text(
                LanguageController.isUrdu ? 'آرڈر کردہ اشیاء:' : 'Items Ordered:',
                textDirection: LanguageController.contentTextDirection,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          '${i.productName} x${i.quantity.toInt()}',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontSize: 14),
                        ),
                        Text(
                          'Rs. ${i.lineTotal.toStringAsFixed(0)}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Text(
                    LanguageController.isUrdu ? 'کل:' : 'Total:',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue),
                  ),
                  Text(
                    'Rs. ${order.total.toStringAsFixed(0)}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              DropdownButtonFormField<OrderStatus>(
                value: order.status,
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontSize: 14),
                decoration: InputDecoration(
                  labelText: LanguageController.isUrdu ? 'آرڈر کی حیثیت اپ ڈیٹ کریں' : 'Update Order Status',
                  labelStyle: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.3) : Colors.grey.shade300),
                  ),
                ),
                items: OrderStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s, 
                    child: Text(
                      s.displayName,
                      textDirection: LanguageController.contentTextDirection,
                    ),
                  );
                }).toList(),
                onChanged: (newStatus) async {
                  if (newStatus != null) {
                    final service = ref.read(storeServiceProvider);
                    await service.updateOrderStatus(order.id, newStatus, order.items);
                    ref.invalidate(storeOrdersProvider(storeId));
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  // Skeleton Loaders
  Widget _buildStoreSkeletonLoader(bool isDark) {
    final baseColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : AppColors.lavender.withValues(alpha: 0.6);
    final highlightColor = isDark ? AppColors.yinMnBlue.withValues(alpha: 0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xxl))),
              const SizedBox(height: AppSpacing.xl),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xxl)))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersSkeletonLoader(bool isDark) {
    final baseColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : AppColors.lavender.withValues(alpha: 0.6);
    final highlightColor = isDark ? AppColors.yinMnBlue.withValues(alpha: 0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Column(
          textDirection: LanguageController.contentTextDirection,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xxl)))),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                height: 72,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)),
              ),
            ),
          ],
        );
      },
    );
  }
}