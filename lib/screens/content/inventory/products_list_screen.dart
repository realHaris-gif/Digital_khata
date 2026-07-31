import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/widgets/inventory/inventory_widgets.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final categoriesListProvider =
    FutureProvider.family<List<Category>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getCategories(userId);
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final stockFilterProvider = StateProvider<String>((ref) => 'all'); // all, low, out

final filteredProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider);
  final stockFilter = ref.watch(stockFilterProvider);

  return repo.getProducts(
    userId: userId,
    categoryId: categoryId,
    searchQuery: search,
    lowStockOnly: stockFilter == 'low',
    outOfStockOnly: stockFilter == 'out',
    limit: 100,
  );
});

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh(String userId) {
    ref.invalidate(filteredProductsProvider(userId));
    ref.invalidate(categoriesListProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final stockFilter = ref.watch(stockFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Products'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product, SKU, or barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                  ),
                ),

                // Category Filter Chips
                ref.watch(categoriesListProvider(userId)).when(
                      data: (categories) {
                        if (categories.isEmpty) return const SizedBox.shrink();
                        return SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('All Categories'),
                                  selected: selectedCategory == null,
                                  onSelected: (_) {
                                    ref.read(selectedCategoryProvider.notifier).state =
                                        null;
                                  },
                                ),
                              ),
                              ...categories.map((cat) {
                                return CategoryChip(
                                  category: cat,
                                  isSelected: selectedCategory == cat.id,
                                  onTap: () {
                                    ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state = (selectedCategory == cat.id)
                                        ? null
                                        : cat.id;
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                const SizedBox(height: 8),

                // Stock Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildStockSegment('All', 'all', stockFilter),
                      const SizedBox(width: 8),
                      _buildStockSegment('Low Stock', 'low', stockFilter),
                      const SizedBox(width: 8),
                      _buildStockSegment('Out of Stock', 'out', stockFilter),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Product List View
                Expanded(
                  child: ref.watch(filteredProductsProvider(userId)).when(
                        data: (products) {
                          if (products.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noResults,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async => _refresh(userId),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () async {
                                    final res = await context
                                        .push('/inventory/product/${product.id}');
                                    if (res == true) _refresh(userId);
                                  },
                                );
                              },
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(
                          child: Text('${l10n.error}: $error'),
                        ),
                      ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await context.push('/inventory/add-product');
          if (res == true) _refresh(userId);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStockSegment(String label, String value, String currentVal) {
    final isSelected = value == currentVal;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(stockFilterProvider.notifier).state = value;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}