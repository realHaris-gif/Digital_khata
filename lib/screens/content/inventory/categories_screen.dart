import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/services/inventory_service.dart';

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final categoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, userId) async {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getCategories(userId);
});

class CategoriesScreen extends ConsumerWidget {
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
    final nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');
    final descController =
        TextEditingController(text: categoryToEdit?.description ?? '');
    final formKey = GlobalKey<FormState>();

    Color selectedColor = categoryToEdit != null
        ? categoryToEdit.getDisplayColor()
        : Colors.teal;

    final presetColors = [
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.indigo,
      Colors.brown,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(isEditing ? 'Edit Category' : 'New Category'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter category name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Category Color',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: presetColors.map((color) {
                          final isSelected = selectedColor.value == color.value;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color;
                              });
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: color,
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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
                  child: Text(
                    isEditing ? 'Update' : 'Create',
                    style: const TextStyle(color: Colors.white),
                  ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Categories'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref, userId),
          ),
        ],
      ),
      body: userId.isEmpty
          ? Center(child: Text(l10n.error))
          : ref.watch(categoriesProvider(userId)).when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No categories added yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal),
                            onPressed: () =>
                                _showCategoryDialog(context, ref, userId),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Add Category',
                                style: TextStyle(color: Colors.white)),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: catColor.withOpacity(0.15),
                            child: Icon(Icons.category, color: catColor),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: category.description != null
                              ? Text(category.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showCategoryDialog(
                                  context,
                                  ref,
                                  userId,
                                  categoryToEdit: category,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
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
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showCategoryDialog(context, ref, userId),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}