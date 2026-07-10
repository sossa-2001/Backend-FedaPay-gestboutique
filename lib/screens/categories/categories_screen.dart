import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../utils/responsive.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final isWide = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: context.responsivePadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catégories',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.categories.length} catégories',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDialog(context),
                  icon: Icon(Icons.add_rounded, size: context.iconMd),
                  label: const Text('Nouvelle catégorie'),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.categories.isEmpty
                ? _buildEmptyState(context)
                : GridView.builder(
                    padding: context.horizontalPadding,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = provider.categories[index];
                      return GlassCard(
                        glowColor: Color(cat.color ?? 0xFF0F9D8A),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      cat.color ?? 0xFF0F9D8A,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _categoryIcon(cat.icon),
                                    color: Color(cat.color ?? 0xFF0F9D8A),
                                    size: context.iconLg,
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: context.iconSm,
                                    color: onSurfaceDim,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer'),
                                    ),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit')
                                      _showDialog(context, category: cat);
                                    if (v == 'delete')
                                      _deleteCategory(context, cat);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: context.fontSizeLg,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                            if (cat.description != null &&
                                cat.description!.isNotEmpty)
                              Text(
                                cat.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fontSizeSm,
                                  color: onSurfaceDim,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_rounded,
            size: 64,
            color: onSurfaceDim.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie',
            style: TextStyle(
              fontSize: context.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez des catégories pour organiser vos produits',
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          category != null ? 'Modifier la catégorie' : 'Nouvelle catégorie',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              final provider = context.read<CategoryProvider>();
              final cat = category ?? Category();
              cat.name = nameCtrl.text;
              cat.description = descCtrl.text.isNotEmpty ? descCtrl.text : null;
              if (category != null) {
                provider.updateCategory(cat);
              } else {
                provider.addCategory(cat);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer'),
        content: Text('Supprimer "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(category.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(int? index) {
    const icons = [
      Icons.category_rounded,
      Icons.inventory_2_rounded,
      Icons.shopping_bag_rounded,
      Icons.fastfood_rounded,
      Icons.local_grocery_store_rounded,
      Icons.devices_rounded,
      Icons.book_rounded,
      Icons.sports_esports_rounded,
      Icons.home_rounded,
      Icons.work_rounded,
    ];
    return icons[(index ?? 0) % icons.length];
  }
}
