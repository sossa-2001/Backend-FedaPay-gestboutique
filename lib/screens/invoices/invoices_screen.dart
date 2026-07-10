import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/order.dart';
import '../../utils/responsive.dart';
import '../../utils/print_utils.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final invoices = provider.orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final companyName = context.select<SettingsProvider, String>(
      (s) => s.companyName,
    );
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final currencyFmt = NumberFormat.currency(
      locale: 'fr',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factures',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${invoices.length} facture(s)',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: invoices.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: context.horizontalPadding,
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final order = invoices[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        glowOpacity: 0.03,
                        child: InkWell(
                          onTap: () =>
                              _showInvoiceDetail(context, order, companyName),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 0),
                            child: isMobile
                                ? _buildMobileCard(
                                    context, order, companyName,
                                    onSurface, onSurfaceDim, currencyFmt,
                                  )
                                : _buildWideCard(
                                    context, order, companyName,
                                    onSurface, onSurfaceDim, currencyFmt,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(
    BuildContext context,
    Order order,
    String companyName,
    Color onSurface,
    Color onSurfaceDim,
    NumberFormat currencyFmt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.description_rounded,
                color: AppColors.primary,
                size: context.iconMd,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                order.orderNumber,
                style: TextStyle(
                  fontSize: context.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
            ),
            Text(
              currencyFmt.format(order.total),
              style: TextStyle(
                fontSize: context.fontSizeMd,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (order.customerName != null) ...[
              Icon(Icons.person_rounded,
                  size: context.fontSizeSm, color: onSurfaceDim),
              const SizedBox(width: 4),
              Text(
                order.customerName!,
                style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim),
              ),
              const SizedBox(width: 12),
            ],
            Icon(Icons.calendar_today_rounded,
                size: context.fontSizeSm, color: onSurfaceDim),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(order.createdAt ?? DateTime.now()),
              style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _actionButton(
              context,
              Icons.receipt_rounded,
              'Facture',
              AppColors.primary,
              () => _printInvoice(order, companyName),
            ),
            const SizedBox(width: 8),
            _actionButton(
              context,
              Icons.local_shipping_rounded,
              'Bon',
              AppColors.success,
              () => _printDeliveryNote(order, companyName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideCard(
    BuildContext context,
    Order order,
    String companyName,
    Color onSurface,
    Color onSurfaceDim,
    NumberFormat currencyFmt,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.description_rounded,
            color: AppColors.primary,
            size: context.iconLg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: TextStyle(
                  fontSize: context.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
              if (order.customerName != null)
                Text(
                  order.customerName!,
                  style: TextStyle(
                    fontSize: context.fontSizeSm,
                    color: onSurfaceDim,
                  ),
                ),
            ],
          ),
        ),
        Text(
          DateFormat('dd/MM/yyyy HH:mm')
              .format(order.createdAt ?? DateTime.now()),
          style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim),
        ),
        const SizedBox(width: 12),
        Text(
          currencyFmt.format(order.total),
          style: TextStyle(
            fontSize: context.fontSizeMd,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(width: 8),
        _actionButton(
          context,
          Icons.receipt_rounded,
          'Facture',
          AppColors.primary,
          () => _printInvoice(order, companyName),
        ),
        const SizedBox(width: 4),
        _actionButton(
          context,
          Icons.local_shipping_rounded,
          'Bon',
          AppColors.success,
          () => _printDeliveryNote(order, companyName),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip == 'Facture'
          ? 'Imprimer la facture'
          : 'Imprimer le bon de livraison',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: context.iconSm, color: color),
        ),
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
            Icons.receipt_long_rounded,
            size: 64,
            color: onSurfaceDim.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune facture',
            style: TextStyle(
              fontSize: context.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les factures apparaîtront ici après chaque vente',
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetail(
    BuildContext context,
    Order order,
    String companyName,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final currencyFmt = NumberFormat.currency(
      locale: 'fr',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final isMobile = context.isMobile;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                      size: context.iconLg,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontSize: context.fontSizeXl,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                _section('Émetteur', [_row(companyName, '', context)], context),
                const SizedBox(height: 12),
                _section('Client', [
                  _row('Nom', order.customerName ?? '—', context),
                ], context),
                const SizedBox(height: 12),
                _section('Facture', [
                  _row('N°', order.orderNumber, context),
                  _row(
                    'Date',
                    '${dateFmt.format(order.createdAt ?? DateTime.now())}',
                    context,
                  ),
                  _row(
                    'Heure',
                    timeFmt.format(order.createdAt ?? DateTime.now()),
                    context,
                  ),
                  _row('Statut', 'Payée', context),
                ], context),
                const SizedBox(height: 16),
                Text(
                  'Articles',
                  style: TextStyle(
                    fontSize: context.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              color: onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 40 : 50,
                          child: Text(
                            'x${item.quantity.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              color: onSurfaceDim,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 70 : 90,
                          child: Text(
                            currencyFmt.format(item.unitPrice),
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              color: onSurfaceDim,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 70 : 90,
                          child: Text(
                            currencyFmt.format(item.totalPrice),
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(thickness: 1),
                const SizedBox(height: 4),
                _totalRow(
                  'Sous-total',
                  currencyFmt.format(order.subtotal),
                  context,
                ),
                if (order.tax > 0)
                  _totalRow('Taxe', currencyFmt.format(order.tax), context),
                if (order.discount > 0)
                  _totalRow(
                    'Remise',
                    currencyFmt.format(order.discount),
                    context,
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: context.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      currencyFmt.format(order.total),
                      style: TextStyle(
                        fontSize: context.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _printInvoice(order, companyName),
                      child: const Text('Imprimer la facture'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _printDeliveryNote(order, companyName),
                      child: const Text('Bon de livraison'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows, BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceDim = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: onSurfaceDim,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: context.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
          Text(
            value,
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurface),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(Order order, String companyName) async {
    await printInvoice(order, companyName);
  }

  Future<void> _printDeliveryNote(Order order, String companyName) async {
    await printDeliveryNote(order, companyName);
  }
}
