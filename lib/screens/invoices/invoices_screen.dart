import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/stock_provider.dart';
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
              () => _printInvoice(order, companyName, context),
            ),
            const SizedBox(width: 8),
            _actionButton(
              context,
              Icons.local_shipping_rounded,
              'Bon',
              AppColors.success,
              () => _printDeliveryNote(order, companyName, context),
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
          () => _printInvoice(order, companyName, context),
        ),
        const SizedBox(width: 4),
        _actionButton(
          context,
          Icons.local_shipping_rounded,
          'Bon',
          AppColors.success,
          () => _printDeliveryNote(order, companyName, context),
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
                _section('Émetteur', [
                  _row(companyName, '', context),
                  if (order.sellerName != null)
                    _row('Vendeur', order.sellerName!, context),
                ], context),
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
                  _row('Statut', _paymentLabel(order.paymentStatus), context),
                  if (order.amountDue > 0)
                    _row('Restant dû', currencyFmt.format(order.amountDue), context),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Montant payé', style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim)),
                          Text(
                            currencyFmt.format(order.amountPaid),
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (order.amountDue > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reste à payer', style: TextStyle(fontSize: context.fontSizeMd, color: AppColors.error)),
                            Text(
                              currencyFmt.format(order.amountDue),
                              style: TextStyle(
                                fontSize: context.fontSizeMd,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 1,
                          color: onSurfaceDim.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Text('Signature client', style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 120,
                          height: 1,
                          color: onSurfaceDim.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Text('Cachet / Signature', style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.print_rounded, size: 16),
                      onPressed: () => _printInvoice(order, companyName, context),
                      label: const Text('Facture'),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      onPressed: () => _printDeliveryNote(order, companyName, context),
                      label: const Text('Bon'),
                    ),
                  ],
                ),
                if (order.status != OrderStatus.cancelled)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.paymentStatus != PaymentStatus.paid)
                        TextButton.icon(
                          icon: const Icon(Icons.payment_rounded, size: 16),
                          onPressed: () => _showEditPayment(ctx, order),
                          label: const Text('Ajuster paiement'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        onPressed: () => _confirmCancel(ctx, order),
                        label: const Text('Annuler la vente'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
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

  void _confirmCancel(BuildContext ctx, Order order) {
    final currencyFmt = NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0);
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la vente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Annuler ${order.orderNumber} ?'),
            const SizedBox(height: 8),
            Text('Les articles seront remis en stock.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (order.amountDue > 0)
              Text('La dette de ${currencyFmt.format(order.amountDue)} sera annulée.', style: TextStyle(fontSize: 12, color: AppColors.warning)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Non')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              final orderProv = ctx.read<OrderProvider>();
              final clientProv = ctx.read<ClientProvider>();
              final stockProv = ctx.read<StockProvider>();
              await orderProv.cancelOrder(
                order,
                stockProvider: stockProv,
                clientProvider: clientProv,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _showEditPayment(BuildContext ctx, Order order) {
    final currencyFmt = NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0);
    final amountCtrl = TextEditingController(text: order.amountPaid.toStringAsFixed(0));

    showDialog(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ajuster le paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${order.orderNumber} — Total: ${currencyFmt.format(order.total)}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Text('Restant dû: ${currencyFmt.format(order.amountDue)}', style: TextStyle(fontSize: 12, color: AppColors.warning)),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nouveau montant payé',
                  prefixText: 'FCFA ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final text = amountCtrl.text.trim();
                  final newAmount = text.isEmpty ? 0.0 : (int.tryParse(text) ?? 0).toDouble();
                  final clamped = newAmount.clamp(0.0, order.total);
                  final PaymentStatus status;
                  if (clamped >= order.total) {
                    status = PaymentStatus.paid;
                  } else if (clamped > 0) {
                    status = PaymentStatus.partial;
                  } else {
                    status = PaymentStatus.unpaid;
                  }
                  Navigator.pop(c);
                  if (!ctx.mounted) return;
                  final orderProv = ctx.read<OrderProvider>();
                  final clientProv = ctx.read<ClientProvider>();
                  await orderProv.updatePayment(
                    order,
                    status,
                    clamped,
                    clientProvider: clientProv,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (c.mounted) Navigator.pop(c);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payée';
      case PaymentStatus.partial:
        return 'Partielle';
      case PaymentStatus.unpaid:
        return 'Non payée';
      case PaymentStatus.deposit:
        return 'Acompte';
    }
  }

  Future<void> _printInvoice(Order order, String companyName, BuildContext context) async {
    final logoBase64 = context.read<SettingsProvider>().logoBase64;
    await printInvoice(order, companyName, logoBase64: logoBase64);
  }

  Future<void> _printDeliveryNote(Order order, String companyName, BuildContext context) async {
    final logoBase64 = context.read<SettingsProvider>().logoBase64;
    await printDeliveryNote(order, companyName, logoBase64: logoBase64);
  }
}
