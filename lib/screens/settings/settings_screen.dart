import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../utils/responsive.dart';
import 'configuration_screen.dart';
import '../subscription/subscription_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paramètres', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            GlassCard(
              glowOpacity: 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Général',
                    style: TextStyle(
                      fontSize: context.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _settingItem(
                    context,
                    Icons.store_rounded,
                    'Nom de l\'entreprise',
                    settings.companyName,
                    onTap: () => _editCompanyName(context, settings),
                    theme: theme,
                  ),
                  _divider(theme),
                  _settingItem(
                    context,
                    Icons.language_rounded,
                    'Langue',
                    'Français',
                    theme: theme,
                  ),
                  _divider(theme),
                  _settingItem(
                    context,
                    Icons.attach_money_rounded,
                    'Devise',
                    'FCFA',
                    theme: theme,
                  ),
                  _divider(theme),
                  _settingItem(
                    context,
                    Icons.calendar_today_rounded,
                    'Format de date',
                    'DD/MM/YYYY',
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (sub.canAccess('cloud_backup'))
              GlassCard(
                glowOpacity: 0.03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: context.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: context.iconMd,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.config.configured
                                      ? auth.config.storeName
                                      : 'Non configurée',
                                  style: TextStyle(
                                    fontSize: context.fontSizeMd,
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  auth.config.configured
                                      ? 'Boutique connectée'
                                      : 'Activez la sauvegarde cloud',
                                  style: TextStyle(
                                    fontSize: context.fontSizeSm,
                                    color: onSurfaceDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (auth.config.configured)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: context.iconMd,
                            )
                          else
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                    _divider(theme),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConfigurationScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.settings_rounded),
                          label: Text(
                            auth.config.configured
                                ? 'Gérer la configuration'
                                : 'Configurer la boutique',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (sub.canAccess('cloud_backup'))
              GlassCard(
                glowOpacity: 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde',
                    style: TextStyle(
                      fontSize: context.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _syncStatusItem(context, sync, theme),
                  if (sync.lastSyncAt != null) ...[
                    _divider(theme),
                    _settingItem(
                      context,
                      Icons.schedule_rounded,
                      'Dernière sauvegarde',
                      _formatDate(sync.lastSyncAt!),
                      theme: theme,
                    ),
                  ],
                  _divider(theme),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.config.backupEnabled
                            ? () => sync.triggerSync()
                            : null,
                        icon: sync.status == SyncStatus.syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Sauvegarder maintenant'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!auth.config.backupEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Activez la sauvegarde dans Configuration pour synchroniser',
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (auth.isLoggedIn)
              GlassCard(
                glowOpacity: 0.03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte',
                      style: TextStyle(
                        fontSize: context.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _settingItem(
                      context,
                      Icons.person_rounded,
                      'Connecté en tant que',
                      auth.currentLogin,
                      theme: theme,
                    ),
                    _divider(theme),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Se déconnecter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GlassCard(
              glowOpacity: 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abonnement',
                    style: TextStyle(
                      fontSize: context.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _settingItem(
                    context,
                    Icons.subscriptions_rounded,
                    'Plan actuel',
                    context.watch<SubscriptionProvider>().planLabel,
                    theme: theme,
                  ),
                  _divider(theme),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.upgrade_rounded),
                        label: const Text('Gérer l\'abonnement'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              glowOpacity: 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: context.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _switchItem(
                    context,
                    'Alerte stock faible',
                    'Recevoir une notification quand le stock est bas',
                    true,
                    theme,
                  ),
                  _divider(theme),
                  _switchItem(
                    context,
                    'Rappels de commandes',
                    'Notifications pour les commandes en attente',
                    false,
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              glowOpacity: 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: context.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _settingItem(
                    context,
                    Icons.info_outline_rounded,
                    'Version',
                    '1.0.0',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _editCompanyName(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.companyName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nom de l\'entreprise'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Entrez le nom de l\'entreprise',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                settings.setCompanyName(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _syncStatusItem(
    BuildContext context,
    SyncProvider sync,
    ThemeData theme,
  ) {
    final onSurface = theme.colorScheme.onSurface;
    IconData icon;
    Color color;
    switch (sync.status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = AppColors.primary;
      case SyncStatus.completed:
        icon = Icons.cloud_done_rounded;
        color = Colors.green;
      case SyncStatus.error:
        icon = Icons.cloud_off_rounded;
        color = Colors.red;
      case SyncStatus.offline:
        icon = Icons.wifi_off_rounded;
        color = onSurface.withValues(alpha: 0.5);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: context.iconMd, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: context.fontSizeMd,
                    color: onSurface,
                  ),
                ),
                Text(
                  sync.statusLabel,
                  style: TextStyle(fontSize: context.fontSizeSm, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingItem(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final onSurface = theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: context.iconMd,
              color: onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.fontSizeMd,
                  color: onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: context.fontSizeMd,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit_rounded,
                size: context.iconSm,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchItem(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ThemeData theme,
  ) {
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fontSizeMd,
                    color: onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.fontSizeSm,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3));
  }
}
