import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import 'store_settings_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeAsync = ref.watch(myStoreProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Digital Store', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final store = storeAsync.value;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StoreSettingsScreen(store: store)),
              );
              ref.invalidate(myStoreProvider);
            },
          ),
        ],
      ),
      body: storeAsync.when(
        data: (store) {
          if (store == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 72, color: Color(0xFFFF7A00)),
                    const SizedBox(height: 16),
                    const Text('Create Your Digital Store',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Setup an online storefront in seconds and take orders directly on WhatsApp or in-app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StoreSettingsScreen()),
                        );
                        ref.invalidate(myStoreProvider);
                      },
                      icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                      label: const Text('Setup Store Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Link Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFFF7A00),
                          backgroundImage: store.logoUrl != null ? NetworkImage(store.logoUrl!) : null,
                          child: store.logoUrl == null
                              ? const Icon(Icons.store_rounded, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.storeName,
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('digitalkhata.app/store/${store.slug}',
                                  style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
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
                  const SizedBox(height: 20),

                  // Orders Overview Metrics
                  ordersAsync.when(
                    data: (orders) {
                      final totalRevenue = orders
                          .where((o) => o.status == OrderStatus.delivered)
                          .fold(0.0, (sum, o) => sum + o.total);
                      final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                title: 'Online Revenue',
                                value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                                icon: Icons.payments_rounded,
                                color: Colors.green,
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                title: 'Pending Orders',
                                value: '$pendingCount',
                                icon: Icons.pending_actions_rounded,
                                color: Colors.amber.shade700,
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                title: 'Total Orders',
                                value: '${orders.length}',
                                icon: Icons.shopping_bag_rounded,
                                color: Colors.blue,
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                title: 'Delivered',
                                value: '${orders.where((o) => o.status == OrderStatus.delivered).length}',
                                icon: Icons.local_shipping_rounded,
                                color: Colors.teal,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text('Recent Customer Orders',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          if (orders.isEmpty)
  const Padding(
    padding: EdgeInsets.all(32),
    child: Center(
      child: Text(
        'No online orders received yet.',
        style: TextStyle(color: Colors.grey),
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
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                        color: isDark ? Colors.white12 : Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    title: Text(order.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '${order.items.length} items • ${order.paymentMethod}\n${order.customerPhone}'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Rs. ${order.total.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading orders: $e'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
        color = Colors.blue;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOrderDetailsModal(BuildContext context, WidgetRef ref, OrderModel order, String storeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Details (${order.customerName})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Address: ${order.customerAddress}'),
              Text('Phone: ${order.customerPhone}'),
              const Divider(height: 24),
              const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.productName} x${i.quantity.toInt()}'),
                        Text('Rs. ${i.lineTotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rs. ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<OrderStatus>(
                value: order.status,
                decoration: const InputDecoration(labelText: 'Update Order Status', border: OutlineInputBorder()),
                items: OrderStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.displayName));
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
            ],
          ),
        );
      },
    );
  }
}