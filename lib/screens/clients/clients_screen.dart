import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/client_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/client.dart';
import '../../models/order.dart';
import '../../utils/responsive.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();
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
                        'Clients',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.clients.length} clients',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDialog(context),
                  icon: Icon(Icons.add_rounded, size: context.iconMd),
                  label: const Text('Nouveau client'),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.clients.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: context.horizontalPadding,
                    itemCount: provider.clients.length,
                    itemBuilder: (context, index) {
                      final client = provider.clients[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        onTap: () => _showHistory(context, client),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_rounded,
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
                                    client.name,
                                    style: TextStyle(
                                      fontSize: context.fontSizeMd,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface,
                                    ),
                                  ),
                                  if (client.phone != null)
                                    Text(
                                      client.phone!,
                                      style: TextStyle(
                                        fontSize: context.fontSizeSm,
                                        color: onSurfaceDim,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (client.email != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  client.email!,
                                  style: TextStyle(
                                    fontSize: context.fontSizeSm,
                                    color: onSurfaceDim,
                                  ),
                                ),
                              ),
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: context.iconSm,
                                color: onSurfaceDim,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'history',
                                  child: Text('Historique'),
                                ),
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
                                if (v == 'history')
                                  _showHistory(context, client);
                                if (v == 'edit')
                                  _showDialog(context, client: client);
                                if (v == 'delete')
                                  _deleteClient(context, client);
                              },
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
            Icons.people_rounded,
            size: 64,
            color: onSurfaceDim.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun client',
            style: TextStyle(
              fontSize: context.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier client',
            style: TextStyle(fontSize: context.fontSizeMd, color: onSurfaceDim),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Client? client}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final nameCtrl = TextEditingController(text: client?.name ?? '');
    final phoneCtrl = TextEditingController(text: client?.phone ?? '');
    final emailCtrl = TextEditingController(text: client?.email ?? '');
    final addressCtrl = TextEditingController(text: client?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(client != null ? 'Modifier le client' : 'Nouveau client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Adresse'),
                maxLines: 2,
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
              if (nameCtrl.text.isEmpty) return;
              final provider = context.read<ClientProvider>();
              final c = client ?? Client();
              c.name = nameCtrl.text;
              c.phone = phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null;
              c.email = emailCtrl.text.isNotEmpty ? emailCtrl.text : null;
              c.address = addressCtrl.text.isNotEmpty ? addressCtrl.text : null;
              if (client != null) {
                provider.updateClient(c);
              } else {
                provider.addClient(c);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteClient(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer'),
        content: Text('Supprimer "${client.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ClientProvider>().deleteClient(client.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, Client client) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final orders = context
        .read<OrderProvider>()
        .orders
        .where(
          (o) =>
              o.customerName == client.name &&
              o.status == OrderStatus.completed,
        )
        .toList();
    final totalDepense = orders.fold<double>(0, (sum, o) => sum + o.total);
    final currencyFmt = NumberFormat.currency(
      locale: 'fr',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${client.name} — Historique'),
        content: SizedBox(
          width: 400,
          child: orders.isEmpty
              ? Padding(
                  padding: context.responsivePadding,
                  child: const Center(child: Text('Aucun achat')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    ...orders.map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dateFmt.format(o.createdAt!)} à ${timeFmt.format(o.createdAt!)}',
                                    style: TextStyle(
                                      fontSize: context.fontSizeSm,
                                      color: onSurfaceDim,
                                    ),
                                  ),
                                  if (o.orderNumber.isNotEmpty)
                                    Text(
                                      o.orderNumber,
                                      style: TextStyle(
                                        fontSize: context.fontSizeSm,
                                        color: onSurfaceDim,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFmt.format(o.total),
                              style: TextStyle(
                                fontSize: context.fontSizeMd,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: context.fontSizeMd,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          currencyFmt.format(totalDepense),
                          style: TextStyle(
                            fontSize: context.fontSizeLg,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
