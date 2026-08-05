import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
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
  const ProductsListScreen({super.key});

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
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.yinMnBlue,
              ),
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
              LanguageController.isUrdu ? 'انوینٹری پروڈکٹس' : 'Inventory Products',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.oxfordBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                onPressed: () => _refresh(userId),
              ),
            ],
          ),
          body: userId.isEmpty
              ? Center(
                  child: Text(
                    l10n.error,
                    textDirection: LanguageController.contentTextDirection,
                  ),
                )
              : Column(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: TextField(
                        controller: _searchController,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                        decoration: InputDecoration(
                          hintText: LanguageController.isUrdu ? 'پروڈکٹ، SKU، یا بارکوڈ تلاش کریں...' : 'Search product, SKU, or barcode...',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.lavender.withValues(alpha: 0.5) : AppColors.spaceCadet.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(Icons.search, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                            ),
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
        
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                                    child: ChoiceChip(
                                      label: Text(
                                        LanguageController.isUrdu ? 'تمام زمرے' : 'All Categories',
                                        textDirection: LanguageController.contentTextDirection,
                                      ),
                                      selected: selectedCategory == null,
                                      selectedColor: AppColors.yinMnBlue,
                                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                      labelStyle: TextStyle(
                                        color: selectedCategory == null
                                            ? Colors.white
                                            : (isDark ? AppColors.lavender : AppColors.oxfordBlue),
                                      ),
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

                    const SizedBox(height: AppSpacing.sm),

                    // Stock Filter Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          _buildStockSegment(LanguageController.isUrdu ? 'سب' : 'All', 'all', stockFilter, isDark),
                          const SizedBox(width: AppSpacing.sm),
                          _buildStockSegment(LanguageController.isUrdu ? 'کم اسٹاک' : 'Low Stock', 'low', stockFilter, isDark),
                          const SizedBox(width: AppSpacing.sm),
                          _buildStockSegment(LanguageController.isUrdu ? 'اسٹاک ختم' : 'Out of Stock', 'out', stockFilter, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Product List View
                    Expanded(
                      child: ref.watch(filteredProductsProvider(userId)).when(
                            data: (products) {
                              if (products.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    textDirection: LanguageController.contentTextDirection,
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 64, color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet),
                                      const SizedBox(height: AppSpacing.lg),
                                      Text(
                                        l10n.noResults,
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: isDark ? AppColors.lavender : AppColors.spaceCadet),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                color: AppColors.yinMnBlue,
                                onRefresh: () async => _refresh(userId),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
                                const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
                            error: (error, _) => Center(
                              child: Text(
                                '${l10n.error}: $error',
                                textDirection: LanguageController.contentTextDirection,
                              ),
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
            backgroundColor: AppColors.yinMnBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStockSegment(String label, String value, String currentVal, bool isDark) {
    final isSelected = value == currentVal;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(stockFilterProvider.notifier).state = value;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.yinMnBlue
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.yinMnBlue
                  : (isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? AppColors.lavender : AppColors.oxfordBlue),
            ),
          ),
        ),
      ),
    );
  }
}