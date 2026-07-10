import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/product_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../utils/responsive.dart';
import '../../utils/print_utils.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final posProvider = context.watch<PosProvider>();
    final isWide = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final isDark = theme.brightness == Brightness.dark;

    final isMobile = !isWide;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isMobile
          ? _buildMobileLayout(
              context,
              theme,
              onSurface,
              onSurfaceDim,
              isDark,
              productProvider,
              posProvider,
            )
          : _buildDesktopLayout(
              context,
              theme,
              onSurface,
              onSurfaceDim,
              isDark,
              productProvider,
              posProvider,
            ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    Color onSurface,
    Color onSurfaceDim,
    bool isDark,
    ProductProvider productProvider,
    PosProvider posProvider,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: context.responsivePadding,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: context.iconSm,
                      color: onSurfaceDim,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        context.isMobile ? 8 : 12,
                      ),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.isMobile ? 10 : 16,
                      vertical: context.isMobile ? 10 : 14,
                    ),
                  ),
                  onChanged: (v) => productProvider.setSearchQuery(v),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: context.horizontalPadding,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: context.isMobile ? 6 : 10,
                    mainAxisSpacing: context.isMobile ? 6 : 10,
                    childAspectRatio: context.isMobile ? 0.75 : 0.85,
                  ),
                  itemCount: productProvider.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => posProvider.addToCart(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildCartPanel(
            context,
            theme,
            onSurface,
            onSurfaceDim,
            isDark,
            posProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    Color onSurface,
    Color onSurfaceDim,
    bool isDark,
    ProductProvider productProvider,
    PosProvider posProvider,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Point de vente',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: onSurfaceDim,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onChanged: (v) => productProvider.setSearchQuery(v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: context.horizontalPadding,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: productProvider.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => posProvider.addToCart(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 340,
          child: _buildCartPanel(
            context,
            theme,
            onSurface,
            onSurfaceDim,
            isDark,
            posProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel(
    BuildContext context,
    ThemeData theme,
    Color onSurface,
    Color onSurfaceDim,
    bool isDark,
    PosProvider posProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.dividerColor),
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: context.responsivePadding,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  size: context.isMobile ? context.iconSm : context.iconMd,
                  color: onSurface,
                ),
                SizedBox(width: context.isMobile ? 6 : 8),
                Text(
                  'Panier',
                  style: TextStyle(
                    fontSize: context.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${posProvider.cartCount} article(s)',
                  style: TextStyle(
                    fontSize: context.fontSizeSm,
                    color: onSurfaceDim,
                  ),
                ),
                if (posProvider.cart.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => posProvider.clearCart(),
                    child: Text(
                      'Vider',
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: posProvider.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_shopping_cart_rounded,
                          size: context.iconLg,
                          color: onSurfaceDim.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: context.isMobile ? 8 : 12),
                        Text(
                          'Panier vide',
                          style: TextStyle(
                            fontSize: context.fontSizeMd,
                            color: onSurfaceDim,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(context.isMobile ? 8 : 12),
                    itemCount: posProvider.cart.length,
                    itemBuilder: (context, index) {
                      final item = posProvider.cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(context.isMobile ? 8 : 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16162A)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(
                            context.isMobile ? 6 : 10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.product.name,
                                    style: TextStyle(
                                      fontSize: context.fontSizeMd,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      posProvider.removeFromCart(index),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: context.iconSm,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.isMobile ? 4 : 8),
                            Row(
                              children: [
                                Text(
                                  NumberFormat.currency(
                                    locale: 'fr',
                                    symbol: 'FCFA',
                                    decimalDigits: 0,
                                  ).format(item.product.price),
                                  style: TextStyle(
                                    fontSize: context.fontSizeSm,
                                    color: onSurfaceDim,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => posProvider.updateQuantity(
                                        index,
                                        item.quantity - 1,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.dividerColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: context.iconSm,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.isMobile ? 8 : 12,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontSize: context.fontSizeMd,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => posProvider.updateQuantity(
                                        index,
                                        item.quantity + 1,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: context.iconSm,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: context.responsivePadding,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: context.fontSizeLg,
                        color: onSurfaceDim,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'fr',
                        symbol: 'FCFA',
                        decimalDigits: 0,
                      ).format(posProvider.subtotal),
                      style: TextStyle(
                        fontSize: context.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.isMobile ? 8 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: posProvider.cart.isEmpty
                        ? null
                        : () => _checkout(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: context.isMobile ? 10 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.isMobile ? 8 : 12,
                        ),
                      ),
                    ),
                    child: Text(
                      'Payer',
                      style: TextStyle(
                        fontSize: context.isMobile
                            ? context.fontSizeMd
                            : context.fontSizeLg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostSaleDialog(
    BuildContext context,
    Order order,
    String companyName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vente enregistrée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: context.iconLg,
                ),
                const SizedBox(width: 8),
                Text(
                  order.orderNumber,
                  style: TextStyle(
                    fontSize: context.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} article(s) - ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA', decimalDigits: 0).format(order.total)}',
              style: TextStyle(
                fontSize: context.fontSizeMd,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Fermer'),
          ),
          OutlinedButton.icon(
            onPressed: () => printDeliveryNote(order, companyName),
            icon: Icon(Icons.receipt_long_rounded, size: context.iconSm),
            label: const Text('Bon de livraison'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => printInvoice(order, companyName),
            icon: Icon(Icons.description_rounded, size: context.iconSm),
            label: const Text('Facture'),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context) {
    final clientProvider = context.read<ClientProvider>();
    String? selectedName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirmer la vente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Client (optionnel) :',
                style: TextStyle(
                  fontSize: context.fontSizeMd,
                  color: Theme.of(
                    ctx,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: selectedName,
                decoration: const InputDecoration(
                  hintText: 'Sélectionner un client',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucun')),
                  ...clientProvider.clients.map(
                    (c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setDialogState(() => selectedName = v),
              ),
              const SizedBox(height: 16),
              const Text('Valider cette transaction ?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ctx.read<PosProvider>().checkout(
                  customerName: selectedName,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  final orderProvider = context.read<OrderProvider>();
                  final settings = context.read<SettingsProvider>();
                  final lastOrder = orderProvider.orders.isNotEmpty
                      ? orderProvider.orders.first
                      : null;
                  if (lastOrder != null) {
                    _showPostSaleDialog(
                      context,
                      lastOrder,
                      settings.companyName,
                    );
                  }
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stockQuantity <= 0;
    final lowStock =
        product.minStock != null && product.stockQuantity <= product.minStock!;

    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: GradientCard(
        gradient: outOfStock
            ? [Colors.grey.shade200, Colors.grey.shade300]
            : [AppColors.primary, AppColors.dark],
        borderRadius: context.isMobile ? 12 : 16,
        padding: EdgeInsets.all(context.isMobile ? 10 : 14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.isMobile ? 32 : 44,
                  height: context.isMobile ? 32 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      context.isMobile ? 8 : 12,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: context.isMobile ? context.iconSm : context.iconMd,
                  ),
                ),
                const Spacer(),
                Text(
                  product.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'fr',
                    symbol: 'FCFA',
                    decimalDigits: 0,
                  ).format(product.price),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.fontSizeSm,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.isMobile ? 6 : 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? AppColors.error.withValues(alpha: 0.3)
                        : lowStock
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    outOfStock
                        ? 'Rupture'
                        : 'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fontSizeCaption,
                    ),
                  ),
                ),
              ],
            ),
            if (outOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Rupture',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: context.fontSizeLg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
