import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import 'product_form_screen.dart';
import '../../utils/responsive.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final auth = context.read<AuthProvider>();
    final canManage = auth.isLoggedIn ? auth.hasPermission('products') : true;
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
                        'Produits',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.products.length} produits enregistrés',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  IconButton(
                    icon: Icon(Icons.sync_rounded, size: context.iconMd),
                    color: onSurfaceDim,
                    tooltip: 'Rafraîchir',
                    onPressed: () => context.read<ProductProvider>().refreshFromCloud(),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: Icon(Icons.add_rounded, size: context.iconSm),
                    label: const Text('Nouveau produit'),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: context.horizontalPadding,
            child: _buildStatsRow(provider, context),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.products.isEmpty
                ? _buildEmptyState(context)
                : _buildProductList(context, provider, isWide, canManage),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProductProvider provider, BuildContext context) {
    return Row(
      children: [
        _statChip(
          Icons.inventory_2_rounded,
          '${provider.products.length}',
          'Total',
          context: context,
        ),
        SizedBox(width: context.isMobile ? 6 : 12),
        _statChip(
          Icons.warning_amber_rounded,
          '${provider.lowStockCount}',
          'Stock bas',
          color: AppColors.warning,
          context: context,
        ),
        SizedBox(width: context.isMobile ? 6 : 12),
        _statChip(
          Icons.block_rounded,
          '${provider.outOfStockCount}',
          'Rupture',
          color: AppColors.error,
          context: context,
        ),
        SizedBox(width: context.isMobile ? 6 : 12),
        _statChip(
          Icons.monetization_on_rounded,
          NumberFormat.currency(
            locale: 'fr',
            symbol: 'FCFA',
            decimalDigits: 0,
          ).format(provider.totalStockValue),
          'Valeur stock',
          isCompact: false,
          context: context,
        ),
      ],
    );
  }

  Widget _statChip(
    IconData icon,
    String value,
    String label, {
    Color color = AppColors.primary,
    bool isCompact = true,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 8 : 12,
        vertical: context.isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E36).withValues(alpha: 0.85)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSm, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? context.fontSizeMd : context.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(
    BuildContext context,
    ProductProvider provider,
    bool isWide,
    bool canManage,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    if (isWide) {
      return Padding(
        padding: context.horizontalPadding,
        child: SingleChildScrollView(
          child: DataTableWidget(
          columns: [
            AppDataColumn(label: 'Produit', flex: 3),
            AppDataColumn(label: 'Prix', flex: 2),
            AppDataColumn(label: 'Stock', flex: 2),
            AppDataColumn(label: 'Statut', flex: 1),
            AppDataColumn(label: '', flex: 1),
          ],
          rows: provider.filteredProducts.map((product) {
            return AppDataRow(
              cells: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: context.iconMd,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: context.fontSizeMd,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                        if (product.barcode != null)
                          Text(
                            product.barcode!,
                            style: TextStyle(
                              fontSize: context.fontSizeSm,
                              color: onSurfaceDim,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'fr',
                    symbol: 'FCFA',
                    decimalDigits: 0,
                  ).format(product.price),
                  style: TextStyle(
                    fontSize: context.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                ),
                Text(
                  '${product.stockQuantity.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: context.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: product.minStock != null &&
                            product.stockQuantity <= product.minStock!
                        ? AppColors.error
                        : onSurface,
                  ),
                ),
                const SizedBox(),
                if (canManage)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_rounded, size: context.iconSm),
                        color: onSurfaceDim,
                        onPressed: () => _showForm(context, product: product),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_rounded, size: context.iconSm),
                        color: AppColors.error,
                        onPressed: () => _confirmDelete(context, product),
                      ),
                    ],
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
    }

    return ListView.builder(
      padding: context.horizontalPadding,
      itemCount: provider.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = provider.filteredProducts[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          glowColor: AppColors.primary,
          glowOpacity: 0.04,
          child: Row(
            children: [
              Container(
                width: context.isMobile ? 40 : 48,
                height: context.isMobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: context.iconMd,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: context.fontSizeMd,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        locale: 'fr',
                        symbol: 'FCFA',
                        decimalDigits: 0,
                      ).format(product.price),
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        color: onSurfaceDim,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.fontSizeSm,
                  color: product.minStock != null &&
                          product.stockQuantity <= product.minStock!
                      ? AppColors.error
                      : onSurfaceDim,
                ),
              ),
              const SizedBox(width: 4),
              if (canManage) ...[
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: context.iconSm),
                  color: onSurfaceDim,
                  onPressed: () => _showForm(context, product: product),
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, size: context.iconSm),
                  color: AppColors.error,
                  onPressed: () => _confirmDelete(context, product),
                ),
              ],
            ],
          ),
        );
      },
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
            Icons.inventory_2_rounded,
            size: context.isMobile ? 48 : 64,
            color: onSurfaceDim.withValues(alpha: 0.3),
          ),
          SizedBox(height: context.isMobile ? 12 : 16),
          Text(
            'Aucun produit',
            style: TextStyle(
              fontSize: context.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier produit pour commencer',
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un produit'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
  }
}
