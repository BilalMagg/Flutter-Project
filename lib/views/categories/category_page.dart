import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../controllers/category_controller.dart';
import '../../models/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().loadCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    int selectedColor = category?.colorIndex ?? 0;
    String selectedIcon = category?.icon ?? 'list';

    final icons = [
      'person', 'work', 'warning', 'favorite', 'shopping_cart',
      'sports_esports', 'school', 'home', 'flight', 'settings',
    ];
    final iconData = [
      Icons.person, Icons.work, Icons.warning, Icons.favorite,
      Icons.shopping_cart, Icons.sports_esports, Icons.school,
      Icons.home, Icons.flight, Icons.settings,
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category != null ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(10, (index) {
                    final color = AppTheme.categoryColors[index];
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = index),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == index
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selectedColor == index
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                        child: selectedColor == index
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Icône', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(10, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icons[index]),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selectedIcon == icons[index]
                              ? AppTheme.categoryColors[selectedColor].withValues(alpha: 0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: selectedIcon == icons[index]
                              ? Border.all(color: AppTheme.categoryColors[selectedColor], width: 2)
                              : null,
                        ),
                        child: Icon(
                          iconData[index],
                          color: selectedIcon == icons[index]
                              ? AppTheme.categoryColors[selectedColor]
                              : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'colorIndex': selectedColor,
                    'icon': selectedIcon,
                  });
                }
              },
              child: Text(category != null ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final catController = context.read<CategoryController>();
      final newCategory = Category(
        id: category?.id,
        name: result['name'],
        colorIndex: result['colorIndex'],
        icon: result['icon'],
      );
      if (category != null) {
        await catController.updateCategory(newCategory);
      } else {
        await catController.createCategory(newCategory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une catégorie'),
                  ),
                ),
              );
            }
            final cat = controller.categories[index - 1];
            final color = AppTheme.categoryColors[
                cat.colorIndex % AppTheme.categoryColors.length];

            final icons = {
              'person': Icons.person,
              'work': Icons.work,
              'warning': Icons.warning,
              'favorite': Icons.favorite,
              'shopping_cart': Icons.shopping_cart,
              'sports_esports': Icons.sports_esports,
              'school': Icons.school,
              'home': Icons.home,
              'flight': Icons.flight,
              'settings': Icons.settings,
            };

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icons[cat.icon] ?? Icons.list,
                    color: color,
                  ),
                ),
                title: Text(cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showCategoryDialog(category: cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20,
                          color: AppTheme.errorColor),
                      onPressed: () => _confirmDelete(cat.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: const Text(
            'Les tâches liées à cette catégorie ne seront pas supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<CategoryController>().deleteCategory(id);
    }
  }
}
