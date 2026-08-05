import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/supplier_model.dart';
import 'package:digital_khata/services/supplier_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

final suppliersProvider = FutureProvider.family<List<Supplier>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final repository = SupplierRepository(supabase);
  return repository.getSuppliers(userId);
});

final supplierSearchProvider = StateProvider<String>((ref) => '');

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

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
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.yinMnBlue),
          scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: AppBar(
            title: Text(
              LanguageController.isUrdu ? 'سپلائرز' : l10n.suppliers,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
              ),
            ),
            centerTitle: true,
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                onPressed: () => _refreshList(userId),
              ),
            ],
          ),
          body: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: LanguageController.isUrdu ? 'تلاش کریں...' : l10n.search,
                    hintStyle: TextStyle(color: isDark ? AppColors.lavender.withValues(alpha: 0.4) : Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue.withValues(alpha: 0.6)),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(supplierSearchProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  onChanged: (value) {
                    ref.read(supplierSearchProvider.notifier).state = value;
                  },
                ),
              ),
              // Suppliers list
              Expanded(
                child: _buildSuppliersList(context, userId, searchQuery, ref, l10n, isDark),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
            foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
            onPressed: () async {
              final res = await context.push('/suppliers/add');
              if (res == true) {
                _refreshList(userId);
              }
            },
            icon: const Icon(Icons.person_add_rounded),
            label: Text(
              LanguageController.isUrdu ? 'سپلائر شامل کریں' : 'Add Supplier',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuppliersList(
    BuildContext context,
    String userId,
    String searchQuery,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (userId.isEmpty) {
      return Center(
        child: Text(
          LanguageController.isUrdu ? 'خرابی' : l10n.error,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(color: isDark ? AppColors.lavender : Colors.grey),
        ),
      );
    }

    return ref.watch(suppliersProvider(userId)).when(
      data: (suppliers) {
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
              textDirection: LanguageController.contentTextDirection,
              children: [
                Icon(Icons.business_rounded, size: 64, color: isDark ? AppColors.lavender.withValues(alpha: 0.4) : Colors.grey.shade400),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  searchQuery.isEmpty 
                      ? (LanguageController.isUrdu ? 'ابھی تک کوئی سپلائر نہیں ہے' : l10n.noSuppliers) 
                      : (LanguageController.isUrdu ? 'کوئی نتیجہ نہیں ملا' : l10n.noResults),
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(fontSize: 15, color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshList(userId),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: filteredSuppliers.length,
            itemBuilder: (context, index) {
              final supplier = filteredSuppliers[index];
              return SupplierCard(
                supplier: supplier,
                onRefreshNeeded: () => _refreshList(userId),
                isDark: isDark,
              );
            },
          ),
        );
      },
      loading: () => _buildSkeletonLoadingState(isDark),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: LanguageController.contentTextDirection,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.lg),
            Text(
              LanguageController.isUrdu ? 'خرابی: $error' : '${l10n.error}: $error',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : AppColors.lavender.withValues(alpha: 0.6);
    final highlightColor = isDark ? AppColors.yinMnBlue.withValues(alpha: 0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 84,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)),
          ),
        );
      },
    );
  }
}

class SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  final VoidCallback onRefreshNeeded;
  final bool isDark;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onRefreshNeeded,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: LanguageController.contentTextDirection,
          children: [
            // Top Row: Leading icon, Name/Phone, and Popup Menu Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.jordyBlue : AppColors.yinMnBlue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                        supplier.name,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.oxfordBlue,
                        ),
                      ),
                      if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          supplier.phone!,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  onSelected: (value) async {
                    if (value == 'view') {
                      context.push('/supplier/${supplier.id}');
                    } else if (value == 'po') {
                      context.push('/suppliers/purchase-order', extra: supplier);
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
                      child: Text(
                        LanguageController.isUrdu ? 'دیکھیں' : l10n.view, 
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'po',
                      child: Text(
                        LanguageController.isUrdu ? 'خریداری کا آرڈر بنائیں' : 'Create Purchase Order', 
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        LanguageController.isUrdu ? 'ترمیم' : l10n.edit, 
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        LanguageController.isUrdu ? 'حذف کریں' : l10n.delete, 
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: AppSpacing.md),
            // Bottom Row: Due Balance & New PO Button safely contained inside
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Expanded(
                  child: Text(
                    LanguageController.isUrdu 
                        ? 'واجب الادا: Rs. ${supplier.currentBalance.toStringAsFixed(2)}' 
                        : '${l10n.due}: Rs. ${supplier.currentBalance.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      color: supplier.currentBalance > 0
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                    foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    context.push('/suppliers/purchase-order', extra: supplier);
                  },
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                  label: Text(
                    LanguageController.isUrdu ? 'نیا پی او' : 'New PO',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text(
          LanguageController.isUrdu ? 'سپلائر حذف کریں' : l10n.deleteSupplier,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LanguageController.isUrdu ? 'کیا آپ واقعی ${supplier.name} کو حذف کرنا چاہتے ہیں؟' : '${l10n.deleteConfirmation} ${supplier.name}?',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(color: isDark ? AppColors.lavender : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LanguageController.isUrdu ? 'منسوخ کریں' : l10n.cancel,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(color: isDark ? AppColors.lavender : Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () async {
              try {
                final supabase = Supabase.instance.client;
                final repository = SupplierRepository(supabase);
                await repository.deleteSupplier(supplier.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  onRefreshNeeded();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageController.isUrdu ? 'سپلائر کامیابی کے ساتھ حذف کر دیا گیا' : l10n.supplierDeleted,
                        textDirection: LanguageController.contentTextDirection,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageController.isUrdu ? 'خرابی: $e' : '${l10n.error}: $e',
                        textDirection: LanguageController.contentTextDirection,
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              LanguageController.isUrdu ? 'حذف کریں' : l10n.delete,
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}