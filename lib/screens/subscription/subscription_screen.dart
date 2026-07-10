import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_plan.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';

class SubscriptionScreen extends StatefulWidget {
  final SubscriptionPlan? initialPlan;
  const SubscriptionScreen({super.key, this.initialPlan});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isAnnual = false;

  @override
  Widget build(BuildContext context) {
    final subProv = context.watch<SubscriptionProvider>();
    final sub = subProv.subscription;
    final isActive = subProv.isActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isActive) _buildActiveBanner(context, sub),
          if (!isActive && sub.isExpired)
            _buildExpiredBanner(context),
          const SizedBox(height: 16),
          _buildBillingToggle(),
          const SizedBox(height: 12),
          ...SubscriptionPlan.plans.map((plan) => _buildPlanCard(
                context,
                plan,
                subProv,
                sub,
                isActive,
              )),
          const SizedBox(height: 24),
          _buildCurrentPlanDetails(context, sub),
          const SizedBox(height: 24),
          _buildContactInfo(context),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Mensuel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !_isAnnual ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Annuel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isAnnual ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (_isAnnual)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('-2 mois',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBanner(BuildContext context, Subscription sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Abonnement actif',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Expire le ${sub.formattedExpiry}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (sub.isExpiringSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${sub.daysRemaining} jrs',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning)),
            ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Votre abonnement a expiré. Choisissez un plan pour continuer.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionProvider prov,
    Subscription sub,
    bool isActive,
  ) {
    final isCurrentPlan = sub.planType == plan.type && isActive;
    final fee = _isAnnual ? plan.annualFee : plan.monthlyFee;
    final period = _isAnnual ? '/an' : '/mois';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentPlan
            ? AppColors.primary.withValues(alpha: 0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(plan.description,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(fee),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                    Text(period,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            if (_isAnnual) ...[
              const SizedBox(height: 2),
              Text(plan.annualSavingsLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF66BB6A),
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16,
                          color: isCurrentPlan
                              ? AppColors.primary
                              : AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )),
            if (plan.extraSecretaryFee > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('+ ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(plan.extraSecretaryFee)}/paire secrétaire+surveillant',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () => _showPaymentDialog(context, prov, plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan
                      ? AppColors.success
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isCurrentPlan
                      ? 'Plan actuel'
                      : 'Choisir ${NumberFormat.currency(locale: 'fr', symbol: '', decimalDigits: 0).format(fee)} $period',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanDetails(BuildContext context, Subscription sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détails de l\'abonnement',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('Plan',
              SubscriptionPlan.fromType(sub.planType).name),
          _detailRow('Début', sub.formattedStart),
          _detailRow('Expiration', sub.formattedExpiry),
          _detailRow('Dernier paiement', sub.formattedLastPayment),
          _detailRow('Facturation', sub.isAnnual ? 'Annuelle' : 'Mensuelle'),
            _detailRow('Frais', sub.formattedFee + sub.billingLabel),
            if (sub.extraSecretariesCount > 0 && SubscriptionPlan.fromType(sub.planType).extraSecretaryFee > 0)
              _detailRow('Paires sup.',
                  '${sub.extraSecretariesCount} (+${(sub.extraSecretariesCount * SubscriptionPlan.fromType(sub.planType).extraSecretaryFee).toStringAsFixed(0)} FCFA)'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic, size: 28, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text('Contact support',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('+229 01 61 14 07 59',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(
      BuildContext context, SubscriptionProvider prov, SubscriptionPlan plan) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final extraCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    String selectedCode = 'BJ';
    bool paying = false;

    final countries = {
      'BJ': ('Bénin', '+229'),
      'CM': ('Cameroun', '+237'),
      'CI': ("Côte d'Ivoire", '+225'),
      'SN': ('Sénégal', '+221'),
      'ML': ('Mali', '+223'),
      'BF': ('Burkina Faso', '+226'),
      'TG': ('Togo', '+228'),
      'NE': ('Niger', '+227'),
      'GN': ('Guinée', '+224'),
      'GH': ('Ghana', '+233'),
      'NG': ('Nigéria', '+234'),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final prefix = countries[selectedCode]!.$2;
          final extraCount = int.tryParse(extraCtrl.text) ?? 0;
          final baseFee = _isAnnual ? plan.annualFee : plan.monthlyFee;
          final totalAmount = baseFee +
              (extraCount * plan.extraSecretaryFee);
          final period = _isAnnual ? '/an' : '/mois';

          return AlertDialog(
            title: const Text('Paiement FedaPay',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            contentPadding:
                const EdgeInsets.fromLTRB(20, 12, 20, 0),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${plan.name} - ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(baseFee)}$period',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Total: ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(totalAmount)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        prefixIcon:
                            Icon(Icons.person, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCode,
                      decoration: const InputDecoration(
                        labelText: 'Pays *',
                        prefixIcon: Icon(Icons.public, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      items: countries.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(
                              '${e.value.$1} (${e.value.$2})',
                              style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() => selectedCode = v!);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Téléphone *',
                        hintText: '01 61 12 34 56',
                        prefixText: '$prefix ',
                        prefixIcon:
                            Icon(Icons.phone, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length < 6) return 'Numéro trop court';
                        if (digits.length > 11) return 'Trop long';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email (optionnel)',
                        prefixIcon: Icon(Icons.email, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(12, 4, 12, 8),
            actions: [
              TextButton(
                onPressed: paying
                    ? null
                    : () => Navigator.pop(ctx),
                child: const Text('Annuler',
                    style: TextStyle(fontSize: 13)),
              ),
              ElevatedButton(
                onPressed: paying
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => paying = true);
                        final phone =
                            '$prefix${phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')}';
                        await prov.payWithFedaPay(
                          context: context,
                          customerName: nameCtrl.text.trim(),
                          customerPhone: phone,
                          customerEmail: emailCtrl.text.trim(),
                          upgradeTo: plan.type,
                          extraSecretaries: extraCount,
                          isAnnual: _isAnnual,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: paying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Payer ${NumberFormat.currency(locale: 'fr', symbol: '', decimalDigits: 0).format(totalAmount)} FCFA',
                        style: const TextStyle(fontSize: 13)),
              ),
            ],
          );
        },
      ),
    );
  }
}
