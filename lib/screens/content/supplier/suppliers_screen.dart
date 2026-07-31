import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/services/supplier_service.dart';

final suppliersProvider = FutureProvider.family<List<Supplier>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final repository = SupplierRepository(supabase);
  return repository.getSuppliers(userId);
});

final supplierSearchProvider = StateProvider<String>((ref) => '');

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  late TextEditingController _searchController;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshList(String userId) {
    ref.invalidate(suppliersProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = _supabase.auth.currentUser?.id ?? '';
    final searchQuery = ref.watch(supplierSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suppliers),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshList(userId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(supplierSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(supplierSearchProvider.notifier).state = value;
              },
            ),
          ),
          // Suppliers list
          Expanded(
            child: _buildSuppliersList(context, userId, searchQuery, ref, l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await context.push('/add-supplier');
          if (res == true) {
            _refreshList(userId);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSuppliersList(
    BuildContext context,
    String userId,
    String searchQuery,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    if (userId.isEmpty) {
      return Center(child: Text(l10n.error));
    }

    return ref.watch(suppliersProvider(userId)).when(
      data: (suppliers) {
        // Filter suppliers based on search query
        List<Supplier> filteredSuppliers = suppliers;
        if (searchQuery.isNotEmpty) {
          filteredSuppliers = suppliers
              .where((s) =>
                  s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  (s.phone?.contains(searchQuery) ?? false))
              .toList();
        }

        if (filteredSuppliers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty ? l10n.noSuppliers : l10n.noResults,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshList(userId),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredSuppliers.length,
            itemBuilder: (context, index) {
              final supplier = filteredSuppliers[index];
              return SupplierCard(
                supplier: supplier,
                onRefreshNeeded: () => _refreshList(userId),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('${l10n.error}: $error'),
          ],
        ),
      ),
    );
  }
}

class SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  final VoidCallback onRefreshNeeded;

  const SupplierCard({
    Key? key,
    required this.supplier,
    required this.onRefreshNeeded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.business,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              Text(
                supplier.phone!,
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(height: 8),
            Text(
              '${l10n.due}: Rs. ${supplier.currentBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: supplier.currentBalance > 0
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'view') {
              context.push('/supplier/${supplier.id}');
            } else if (value == 'edit') {
              final res = await context.push('/edit-supplier/${supplier.id}');
              if (res == true) {
                onRefreshNeeded();
              }
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, ref, l10n);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Text(l10n.view),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text(l10n.edit),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => context.push('/supplier/${supplier.id}'),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSupplier),
        content: Text('${l10n.deleteConfirmation} ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final supabase = Supabase.instance.client;
                final repository = SupplierRepository(supabase);
                await repository.deleteSupplier(supplier.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  onRefreshNeeded();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.supplierDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}