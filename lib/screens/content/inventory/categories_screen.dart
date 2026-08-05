import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/services/inventory_service.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final categoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getCategories(userId);
});

class CategoriesScreen extends ConsumerWidget {
  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  const CategoriesScreen({Key? key}) : super(key: key);

  void _refresh(WidgetRef ref, String userId) {
    ref.invalidate(categoriesProvider(userId));
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    Category? categoryToEdit,
  }) {
    final isEditing = categoryToEdit != null;
    final isDark = ThemeController.isDarkMode;
    final nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');
    final descController =
        TextEditingController(text: categoryToEdit?.description ?? '');
    final formKey = GlobalKey<FormState>();

    Color selectedColor = categoryToEdit != null
        ? categoryToEdit.getDisplayColor()
        : yinMnBlue;

    final presetColors = [
      yinMnBlue,
      spaceCadet,
      jordyBlue,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? spaceCadet : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
              ),
              title: Text(
                isEditing 
                    ? (LanguageController.isUrdu ? 'زمرے میں ترمیم کریں' : 'Edit Category') 
                    : (LanguageController.isUrdu ? 'نیا زمرہ' : 'New Category'),
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? Colors.white : oxfordBlue),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      AppFormTextField(
                        controller: nameController,
                        autofocus: true,
                        labelText: LanguageController.isUrdu ? 'زمرے کا نام *' : 'Category Name *',
                        hintText: LanguageController.isUrdu ? 'مثال کے طور پر، کریانہ' : 'e.g. Groceries',
                        prefixIcon: Icons.category_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? (LanguageController.isUrdu ? 'زمرے کا نام درج کریں' : 'Enter category name')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AppFormTextField(
                        controller: descController,
                        labelText: LanguageController.isUrdu ? 'تفصیل (اختیاری)' : 'Description (Optional)',
                        hintText: LanguageController.isUrdu ? 'مختصر تفصیل' : 'Short description',
                        prefixIcon: Icons.notes_outlined,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: LanguageController.isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          LanguageController.isUrdu ? 'زمرے کا رنگ' : 'Category Color',
                          textDirection: LanguageController.contentTextDirection,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? lavender : oxfordBlue,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        textDirection: LanguageController.contentTextDirection,
                        children: presetColors.map((color) {
                          final isSelected = selectedColor.value == color.value;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: isSelected ? 10 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                FormSecondaryButton(
                  label: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                  onPressed: () => Navigator.pop(ctx),
                ),
                FormPrimaryButton(
                  label: isEditing 
                      ? (LanguageController.isUrdu ? 'اپ ڈیٹ کریں' : 'Update') 
                      : (LanguageController.isUrdu ? 'تخلیق کریں' : 'Create'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final repo = ref.read(inventoryRepoProvider);
                    final colorHex = selectedColor.value.toString();

                    if (isEditing) {
                      await repo.updateCategory(
                        categoryId: categoryToEdit.id,
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        color: colorHex,
                        icon: categoryToEdit.icon,
                      );
                    } else {
                      await repo.createCategory(
                        userId: userId,
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        color: colorHex,
                      );
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh(ref, userId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: yinMnBlue,
            ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : lavender.withValues(alpha: 0.3),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            LanguageController.isUrdu ? 'انوینٹری کے زمرے' : 'Inventory Categories',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              color: isDark ? Colors.white : oxfordBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: isDark ? jordyBlue : spaceCadet),
              onPressed: () => _refresh(ref, userId),
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
            : ref.watch(categoriesProvider(userId)).when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Icon(Icons.category_outlined,
                                size: 64, color: isDark ? jordyBlue : spaceCadet),
                            const SizedBox(height: 16),
                            Text(
                              LanguageController.isUrdu ? 'ابھی تک کوئی زمرہ شامل نہیں کیا گیا۔' : 'No categories added yet.',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? lavender : spaceCadet,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: yinMnBlue,
                              ),
                              onPressed: () =>
                                  _showCategoryDialog(context, ref, userId),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                LanguageController.isUrdu ? 'زمرہ شامل کریں' : 'Add Category',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final catColor = category.getDisplayColor();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: isDark ? spaceCadet.withValues(alpha: 0.6) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? jordyBlue.withValues(alpha: 0.2) : lavender,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: catColor.withValues(alpha: 0.15),
                              child: Icon(Icons.category, color: catColor),
                            ),
                            title: Text(
                              category.name,
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : oxfordBlue,
                              ),
                            ),
                            subtitle: category.description != null
                                ? Text(
                                    category.description!,
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      color: isDark ? lavender.withValues(alpha: 0.7) : spaceCadet.withValues(alpha: 0.6),
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: LanguageController.contentTextDirection,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: isDark ? jordyBlue : yinMnBlue),
                                  onPressed: () => _showCategoryDialog(
                                    context,
                                    ref,
                                    userId,
                                    categoryToEdit: category,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    final repo = ref.read(inventoryRepoProvider);
                                    await repo.deleteCategory(category.id);
                                    _refresh(ref, userId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: yinMnBlue)),
                  error: (e, _) => Center(
                    child: Text(
                      '${l10n.error}: $e',
                      textDirection: LanguageController.contentTextDirection,
                    ),
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: yinMnBlue,
          onPressed: () => _showCategoryDialog(context, ref, userId),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}