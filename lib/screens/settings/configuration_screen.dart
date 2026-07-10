import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../models/store_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../utils/responsive.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _nameCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureSecPassword = true;

  // Secretary form
  final _secNameCtrl = TextEditingController();
  final _secLoginCtrl = TextEditingController();
  final _secPasswordCtrl = TextEditingController();
  final _secEmailCtrl = TextEditingController();
  bool _showSecretaryForm = false;
  Secretary _editingSecretary = Secretary();
  String _selectedRole = 'secrétaire';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailCtrl.dispose();
    _secNameCtrl.dispose();
    _secLoginCtrl.dispose();
    _secPasswordCtrl.dispose();
    _secEmailCtrl.dispose();
    super.dispose();
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            const Text(
              'Aucune connexion internet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'La création d\'une boutique nécessite une connexion internet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final login = _loginCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || login.isEmpty || password.isEmpty) {
      setState(() => _error = 'Tous les champs sont requis');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final err = await auth.configureStore(name, login, password, email: email);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    if (err != null && err == 'NO_INTERNET') {
      if (!mounted) return;
      setState(() => _loading = false);
      _showNoInternetDialog();
    } else if (err != null) {
      setState(() => _error = err);
    } else {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boutique créée. Connectez-vous avec vos identifiants.')),
      );
    }
  }

  Future<void> _addSecretary() async {
    final name = _secNameCtrl.text.trim();
    final login = _secLoginCtrl.text.trim();
    final password = _secPasswordCtrl.text.trim();
    final email = _secEmailCtrl.text.trim();
    if (name.isEmpty || login.isEmpty) return;
    if (_editingSecretary.id.isEmpty && password.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final sec = Secretary()
      ..name = name
      ..login = login
      ..password = password
      ..email = email
      ..role = _editingSecretary.role
      ..canViewDashboard = _editingSecretary.canViewDashboard
      ..canManageProducts = _editingSecretary.canManageProducts
      ..canManageClients = _editingSecretary.canManageClients
      ..canManageOrders = _editingSecretary.canManageOrders
      ..canManagePos = _editingSecretary.canManagePos
      ..canManageStock = _editingSecretary.canManageStock
      ..canViewReports = _editingSecretary.canViewReports
      ..canManageSettings = _editingSecretary.canManageSettings
      ..canManageSecretaries = _editingSecretary.canManageSecretaries;
    String? err;
    if (_editingSecretary.id.isNotEmpty) {
      sec.id = _editingSecretary.id;
      err = await auth.updateSecretary(sec);
    } else {
      err = await auth.addSecretary(sec);
    }
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      setState(() {
        _showSecretaryForm = false;
        _secNameCtrl.clear();
        _secLoginCtrl.clear();
        _secPasswordCtrl.clear();
        _secEmailCtrl.clear();
        _editingSecretary = Secretary();
        _selectedRole = 'secrétaire';
      });
    }
  }

  Widget _buildPermissionCheck(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Configuration')),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!auth.config.configured) ...[
              GlassCard(
                glowOpacity: 0.03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activer la sauvegarde',
                      style: TextStyle(
                        fontSize: context.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Créez votre boutique pour activer la synchronisation cloud.',
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nom de la boutique',
                        prefixIcon: const Icon(Icons.store_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _loginCtrl,
                      decoration: InputDecoration(
                        labelText: 'Login administrateur',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email de récupération (Gmail)',
                        prefixIcon: const Icon(Icons.email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Activer la sauvegarde'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              GlassCard(
                glowOpacity: 0.03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boutique',
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
                      'Nom',
                      auth.config.storeName,
                      theme: theme,
                    ),
                    _divider(theme),
                    _settingItem(
                      context,
                      Icons.person_rounded,
                      'Administrateur',
                      auth.config.adminLogin,
                      theme: theme,
                    ),
                    _divider(theme),
                    _settingItem(
                      context,
                      Icons.email_rounded,
                      'Email',
                      auth.config.email,
                      theme: theme,
                    ),
                    _divider(theme),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_upload_rounded,
                            size: context.iconMd,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sauvegarde automatique',
                              style: TextStyle(
                                fontSize: context.fontSizeMd,
                                color: onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: auth.config.backupEnabled,
                            activeTrackColor: AppColors.primary,
                            onChanged: (_) => auth.toggleBackup(),
                          ),
                        ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Secrétaires',
                          style: TextStyle(
                            fontSize: context.fontSizeLg,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_add_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _showSecretaryForm = !_showSecretaryForm;
                              _editingSecretary = Secretary();
                              _selectedRole = 'secrétaire';
                            });
                          },
                        ),
                      ],
                    ),
                    if (_showSecretaryForm) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _secNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _secLoginCtrl,
                        decoration: InputDecoration(
                          labelText: 'Login',
                          prefixIcon: const Icon(Icons.login_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _secPasswordCtrl,
                        obscureText: _obscureSecPassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureSecPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                            onPressed: () => setState(() => _obscureSecPassword = !_obscureSecPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _secEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email de récupération',
                          prefixIcon: const Icon(Icons.email_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rôle',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _roleChip('secrétaire')),
                          const SizedBox(width: 12),
                          Expanded(child: _roleChip('surveillant')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Permissions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      _buildPermissionCheck(
                        'Tableau de bord',
                        _editingSecretary.canViewDashboard,
                        (v) => _editingSecretary.canViewDashboard = v,
                      ),
                      _buildPermissionCheck(
                        'Produits',
                        _editingSecretary.canManageProducts,
                        (v) => _editingSecretary.canManageProducts = v,
                      ),
                      _buildPermissionCheck(
                        'Clients',
                        _editingSecretary.canManageClients,
                        (v) => _editingSecretary.canManageClients = v,
                      ),
                      _buildPermissionCheck(
                        'Commandes',
                        _editingSecretary.canManageOrders,
                        (v) => _editingSecretary.canManageOrders = v,
                      ),
                      _buildPermissionCheck(
                        'Vendre',
                        _editingSecretary.canManagePos,
                        (v) => _editingSecretary.canManagePos = v,
                      ),
                      _buildPermissionCheck(
                        'Stock',
                        _editingSecretary.canManageStock,
                        (v) => _editingSecretary.canManageStock = v,
                      ),
                      _buildPermissionCheck(
                        'Rapports',
                        _editingSecretary.canViewReports,
                        (v) => _editingSecretary.canViewReports = v,
                      ),
                      _buildPermissionCheck(
                        'Paramètres',
                        _editingSecretary.canManageSettings,
                        (v) => _editingSecretary.canManageSettings = v,
                      ),
                      _buildPermissionCheck(
                        'Secrétaires',
                        _editingSecretary.canManageSecretaries,
                        (v) => _editingSecretary.canManageSecretaries = v,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addSecretary,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            _editingSecretary.id.isNotEmpty
                                ? 'Modifier le secrétaire'
                                : 'Ajouter le secrétaire',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (auth.secretaries.isEmpty && !_showSecretaryForm)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucun secrétaire',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ...auth.secretaries.map(
                      (sec) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              sec.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            sec.name,
                            style: TextStyle(
                              fontSize: context.fontSizeMd,
                              color: onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.login,
                                style: TextStyle(
                                  fontSize: context.fontSizeSm,
                                  color: onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sec.role == 'surveillant'
                                      ? AppColors.warning.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sec.role == 'surveillant'
                                      ? 'Surveillant'
                                      : 'Secrétaire',
                                  style: TextStyle(
                                    fontSize: context.fontSizeCaption,
                                    color: sec.role == 'surveillant'
                                        ? AppColors.warning
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                ),
                                onPressed: () {
                                  _secNameCtrl.text = sec.name;
                                  _secLoginCtrl.text = sec.login;
                                  _secPasswordCtrl.text = '';
                                  _secEmailCtrl.text = sec.email;
                                  setState(() {
                                    _editingSecretary = sec;
                                    _selectedRole = sec.role;
                                    _showSecretaryForm = true;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        'Supprimer le secrétaire',
                                      ),
                                      content: Text(
                                        'Supprimer "${sec.name}" ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            ctx,
                                          ),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            auth.deleteSecretary(sec.id);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _settingItem(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    required ThemeData theme,
  }) {
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
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
              style: TextStyle(fontSize: context.fontSizeMd, color: onSurface),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: context.fontSizeMd,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3));
  }

  Widget _roleChip(String role) {
    final isSelected = _selectedRole == role;
    final label = role == 'secrétaire' ? 'Secrétaire' : 'Surveillant';
    final icon = role == 'secrétaire'
        ? Icons.person_rounded
        : Icons.visibility_rounded;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _editingSecretary.applyRole(role);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
