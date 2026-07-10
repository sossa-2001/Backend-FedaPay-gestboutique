import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/stock_movement.dart';
import '../../models/product.dart';
import '../../widgets/glassmorphism.dart';
import '../../utils/responsive.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final productProvider = context.watch<ProductProvider>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: context.responsivePadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${productProvider.products.length} produits',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showMovementDialog(context),
                        icon: Icon(Icons.add_rounded, size: context.iconMd),
                        label: const Text('Mouvement'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Produits en stock',
                    style: TextStyle(
                      fontSize: context.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: context.horizontalPadding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = productProvider.products[index];
                return _ProductStockCard(
                  product: product,
                  onTap: () => _showEditStockDialog(context, product),
                );
              }, childCount: productProvider.products.length),
            ),
          ),
          SliverPadding(
            padding: context.responsivePadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Mouvements récents',
                    style: TextStyle(
                      fontSize: context.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: context.horizontalPadding,
            sliver: stockProvider.isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : stockProvider.movements.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(context))
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final mov = stockProvider.movements[index];
                      final product = productProvider.products
                          .where((p) => p.id == mov.productId)
                          .firstOrNull;
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        glowOpacity: 0.03,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _movementColor(
                                  mov.type,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _movementIcon(mov.type),
                                color: _movementColor(mov.type),
                                size: context.iconMd,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product?.name ??
                                        'Produit #${mov.productId}',
                                    style: TextStyle(
                                      fontSize: context.fontSizeMd,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface,
                                    ),
                                  ),
                                  if (mov.reason != null)
                                    Text(
                                      mov.reason!,
                                      style: TextStyle(
                                        fontSize: context.fontSizeSm,
                                        color: onSurfaceDim,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              _movementLabel(mov),
                              style: TextStyle(
                                fontSize: context.fontSizeMd,
                                fontWeight: FontWeight.w600,
                                color: _movementColor(mov.type),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat(
                                'dd/MM HH:mm',
                              ).format(mov.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: context.fontSizeSm,
                                color: onSurfaceDim,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: stockProvider.movements.length),
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
            Icons.swap_vert_rounded,
            size: 64,
            color: onSurfaceDim.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun mouvement',
            style: TextStyle(
              fontSize: context.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les mouvements de stock apparaîtront ici',
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
        ],
      ),
    );
  }

  Color _movementColor(StockMoveType type) {
    switch (type) {
      case StockMoveType.entry:
        return AppColors.success;
      case StockMoveType.exit:
        return AppColors.error;
      case StockMoveType.adjustment:
        return AppColors.warning;
    }
  }

  IconData _movementIcon(StockMoveType type) {
    switch (type) {
      case StockMoveType.entry:
        return Icons.arrow_downward_rounded;
      case StockMoveType.exit:
        return Icons.arrow_upward_rounded;
      case StockMoveType.adjustment:
        return Icons.tune_rounded;
    }
  }

  String _movementLabel(StockMovement mov) {
    final prefix = mov.type == StockMoveType.entry
        ? '+'
        : mov.type == StockMoveType.exit
        ? '-'
        : '→ ';
    return '$prefix${mov.quantity.toStringAsFixed(1)}';
  }

  void _showEditStockDialog(BuildContext context, Product product) {
    final stockCtrl = TextEditingController(
      text: product.stockQuantity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité en stock',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(stockCtrl.text);
              if (newQty == null || newQty < 0) return;
              final stockProvider = context.read<StockProvider>();
              final movement = StockMovement()
                ..productId = product.id
                ..type = StockMoveType.adjustment
                ..quantity = newQty
                ..reason = 'Mise à jour manuelle';
              stockProvider.addMovement(movement);
              Navigator.pop(ctx);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showMovementDialog(BuildContext context) {
    final products = context.read<ProductProvider>().products;
    int? selectedProductId;
    StockMoveType selectedType = StockMoveType.entry;
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Nouveau mouvement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedProductId,
                decoration: const InputDecoration(labelText: 'Produit *'),
                items: products
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedProductId = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<StockMoveType>(
                segments: const [
                  ButtonSegment(
                    value: StockMoveType.entry,
                    label: Text('Entrée'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: StockMoveType.exit,
                    label: Text('Sortie'),
                    icon: Icon(Icons.remove),
                  ),
                  ButtonSegment(
                    value: StockMoveType.adjustment,
                    label: Text('Ajustement'),
                    icon: Icon(Icons.tune),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) =>
                    setDialogState(() => selectedType = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantité *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Motif'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProductId == null || qtyCtrl.text.isEmpty) return;
                final stockProvider = context.read<StockProvider>();
                final movement = StockMovement()
                  ..productId = selectedProductId!
                  ..type = selectedType
                  ..quantity = double.tryParse(qtyCtrl.text) ?? 0
                  ..reason = reasonCtrl.text.isNotEmpty
                      ? reasonCtrl.text
                      : null;
                stockProvider.addMovement(movement);
                Navigator.pop(ctx);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductStockCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductStockCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final lowStock =
        product.minStock != null && product.stockQuantity <= product.minStock!;
    final outOfStock = product.stockQuantity <= 0;

    Color stockColor;
    if (outOfStock) {
      stockColor = AppColors.error;
    } else if (lowStock) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      glowOpacity: 0.03,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  outOfStock
                      ? Icons.inventory_2_rounded
                      : Icons.check_circle_rounded,
                  color: stockColor,
                  size: context.iconMd,
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
                    if (product.minStock != null)
                      Text(
                        'Seuil: ${product.minStock!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.fontSizeSm,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.stockQuantity.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: context.fontSizeXl,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                  Text(
                    outOfStock
                        ? 'Rupture'
                        : lowStock
                        ? 'Stock bas'
                        : 'En stock',
                    style: TextStyle(
                      fontSize: context.fontSizeCaption,
                      fontWeight: FontWeight.w500,
                      color: stockColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_rounded,
                size: context.iconSm,
                color: onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
