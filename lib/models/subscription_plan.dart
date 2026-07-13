import 'package:intl/intl.dart';

enum PlanType { soloStandard, soloPro, soloProDb, soloProMulti }

class SubscriptionPlan {
  final PlanType type;
  final String name;
  final String description;
  final double monthlyFee;
  final int extraSecretaryFee;
  final List<String> features;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.monthlyFee,
    this.extraSecretaryFee = 0,
    required this.features,
  });

  String get formattedFee =>
      NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(monthlyFee);

  String get formattedAnnualFee =>
      NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(annualFee);

  double get annualFee => monthlyFee * 10;

  String get annualSavingsLabel =>
      'Économisez ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format((monthlyFee * 12) - annualFee)}/an';

  String get extraFeeLabel =>
      '+ ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(extraSecretaryFee)}/paire secrétaire+surveillant';

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      type: PlanType.soloStandard,
      name: 'Solo Standard',
      description: 'Gestion des produits, stocks, clients et rapports',
      monthlyFee: 15000,
      features: [
        'Gestion des produits',
        'Gestion des catégories',
        'Gestion des clients',
        'Gestion des stocks',
        'Rapports détaillés',
      ],
    ),
    SubscriptionPlan(
      type: PlanType.soloPro,
      name: 'Solo Pro',
      description: 'Gestion + facturation et point de vente',
      monthlyFee: 30000,
      features: [
        'Tout du plan Solo Standard',
        'Point de vente (POS)',
        'Facturation et devis',
        'Historique des ventes',
        'Rapports détaillés',
        'Impression tickets/factures',
      ],
    ),
    SubscriptionPlan(
      type: PlanType.soloProDb,
      name: 'Solo Pro + DB',
      description: 'Base de données en ligne + secrétaire + surveillance',
      monthlyFee: 45000,
      features: [
        'Tout du plan Solo Pro',
        'Accès base de données en ligne',
        'Gestion des secrétaires',
        'Gestion des surveillants',
        '1 secrétaire + surveillant inclus',
      ],
    ),
    SubscriptionPlan(
      type: PlanType.soloProMulti,
      name: 'Solo Pro + DB Multi',
      description: 'Multi-secrétaire + multi-surveillance',
      monthlyFee: 100,
      features: [
        'Tout du plan Solo Pro + DB',
        'Multi-secrétaires',
        'Multi-surveillants',
        '4 secrétaires + surveillants inclus',
      ],
    ),
  ];

  static SubscriptionPlan fromType(PlanType type) =>
      plans.firstWhere((p) => p.type == type);
}

class Subscription {
  PlanType planType;
  bool isActive;
  DateTime? startDate;
  DateTime? expiryDate;
  DateTime? lastPaymentDate;
  int extraSecretariesCount;
  bool autoRenew;
  bool isAnnual;

  Subscription({
    this.planType = PlanType.soloStandard,
    this.isActive = false,
    this.startDate,
    this.expiryDate,
    this.lastPaymentDate,
    this.extraSecretariesCount = 0,
    this.autoRenew = true,
    this.isAnnual = false,
  });

  double get effectiveMonthlyFee {
    final plan = SubscriptionPlan.fromType(planType);
    final base = isAnnual ? plan.annualFee / 12 : plan.monthlyFee;
    return base + (extraSecretariesCount * plan.extraSecretaryFee);
  }

  double get totalFee {
    final plan = SubscriptionPlan.fromType(planType);
    final base = isAnnual ? plan.annualFee : plan.monthlyFee;
    return base + (extraSecretariesCount * plan.extraSecretaryFee);
  }

  String get billingLabel => isAnnual ? '/an' : '/mois';

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  bool get isExpiringSoon =>
      expiryDate != null &&
      expiryDate!.difference(DateTime.now()).inDays <= 7 &&
      !isExpired;

  int get daysRemaining =>
      expiryDate != null ? expiryDate!.difference(DateTime.now()).inDays : 0;

  String get formattedExpiry => expiryDate != null
      ? DateFormat('dd/MM/yyyy').format(expiryDate!)
      : 'Non défini';

  String get formattedStart => startDate != null
      ? DateFormat('dd/MM/yyyy').format(startDate!)
      : 'Non défini';

  String get formattedLastPayment => lastPaymentDate != null
      ? DateFormat('dd/MM/yyyy').format(lastPaymentDate!)
      : 'Jamais';

  String get formattedFee =>
      NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(effectiveMonthlyFee);

  Map<String, dynamic> toJson() => {
        'planType': planType.index,
        'isActive': isActive,
        'startDate': startDate?.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'lastPaymentDate': lastPaymentDate?.toIso8601String(),
        'extraSecretariesCount': extraSecretariesCount,
        'autoRenew': autoRenew,
        'isAnnual': isAnnual,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        planType: PlanType.values[json['planType'] ?? 0],
        isActive: json['isActive'] ?? false,
        startDate:
            json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'])
            : null,
        lastPaymentDate: json['lastPaymentDate'] != null
            ? DateTime.parse(json['lastPaymentDate'])
            : null,
        extraSecretariesCount: json['extraSecretariesCount'] ?? 0,
        autoRenew: json['autoRenew'] ?? true,
        isAnnual: json['isAnnual'] ?? false,
      );
}
