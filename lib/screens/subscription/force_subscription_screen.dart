import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_plan.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'subscription_screen.dart';

class ForceSubscriptionScreen extends StatefulWidget {
  const ForceSubscriptionScreen({super.key});

  @override
  State<ForceSubscriptionScreen> createState() =>
      _ForceSubscriptionScreenState();
}

class _ForceSubscriptionScreenState extends State<ForceSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDialog());
    context.read<SubscriptionProvider>().addListener(_onSubChanged);
  }

  @override
  void dispose() {
    context.read<SubscriptionProvider>().removeListener(_onSubChanged);
    super.dispose();
  }

  void _onSubChanged() {
    if (context.read<SubscriptionProvider>().isActive && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _openDialog() {
    if (!mounted) return;
    if (context.read<SubscriptionProvider>().isActive) return;
    _showDialog();
  }

  void _showDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Abonnement requis',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Votre abonnement a expiré. Choisissez un plan pour continuer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ...SubscriptionPlan.plans.map((plan) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubscriptionScreen(initialPlan: plan),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(
                                      '${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(plan.monthlyFee)}/mois',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withValues(alpha: 0.7));
  }
}