import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart';
import '../models/subscription_plan.dart';
import '../services/fedapay_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final DatabaseService _db;
  final FirebaseFirestore _firestore;
  String? _userId;
  Subscription _subscription;
  bool _isLoading = false;
  bool _initialized = false;
  Timer? _expiryTimer;
  int? _pendingTransactionId;
  PlanType? _pendingPlan;
  int _pendingExtraSecretaries = 0;
  bool _pendingIsAnnual = false;

  static const String _storageKey = 'subscription_data';

  SubscriptionProvider(this._db, this._firestore, [this._userId])
      : _subscription = Subscription();

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId != null) {
      _initialized = false;
      init();
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    if (_userId != null) {
      await _loadFromFirestore();
    }

    if (_subscription.startDate == null) {
      final raw = await _db.getSetting(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          _subscription = Subscription.fromJson(_parsePipeString(raw));
        } catch (_) {}
      }
    }

    if (_subscription.startDate == null) {
      _subscription.isActive = true;
      _subscription.startDate = DateTime.now();
      _subscription.expiryDate = DateTime.now().add(const Duration(days: 30));
      _subscription.lastPaymentDate = DateTime.now();
      _subscription.planType = PlanType.soloStandard;
      await _persist();
    } else {
      await _persist();
    }

    _initialized = true;
    notifyListeners();
    _startExpiryTimer();
    checkPendingTransaction();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(_userId)
          .collection('settings')
          .doc('subscription')
          .get();
      if (doc.exists && doc.data() != null) {
        _subscription = Subscription.fromJson(doc.data()!);
      }
    } catch (_) {}
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_subscription.isExpired) {
        notifyListeners();
      }
    });
  }

  Map<String, dynamic> _parsePipeString(String raw) {
    final map = <String, dynamic>{};
    for (final pair in raw.split('|')) {
      final idx = pair.indexOf(':');
      if (idx == -1) continue;
      map[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
    return map;
  }

  Subscription get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  bool get isActive => _subscription.isActive && !_subscription.isExpired;

  String get planLabel {
    if (!isActive) return 'Inactif';
    final plan = SubscriptionPlan.fromType(_subscription.planType);
    final period = _subscription.isAnnual ? '/an' : '/mois';
    return '${plan.name} - ${plan.monthlyFee.toStringAsFixed(0)} FCFA$period';
  }

  Future<void> _persist() async {
    final json = _subscription.toJson();
    final raw = json.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _db.setSetting(_storageKey, raw);
    if (_userId != null) {
      try {
        await _firestore
            .collection('stores')
            .doc(_userId)
            .collection('settings')
            .doc('subscription')
            .set(json);
      } catch (_) {}
    }
  }

  Future<bool> activateSubscription(PlanType planType,
      {int extraSecretaries = 0, bool isAnnual = false}) async {
    _isLoading = true;
    notifyListeners();

    _subscription.planType = planType;
    _subscription.isActive = true;
    _subscription.isAnnual = isAnnual;
    final now = DateTime.now();
    _subscription.startDate ??= now;
    final base = _subscription.expiryDate != null && !_subscription.isExpired
        ? _subscription.expiryDate!
        : now;
    _subscription.expiryDate =
        base.add(isAnnual ? const Duration(days: 365) : const Duration(days: 30));
    _subscription.lastPaymentDate = now;
    _subscription.extraSecretariesCount = extraSecretaries;
    await _persist();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> renewSubscription() async {
    _isLoading = true;
    notifyListeners();

    if (_subscription.isActive && !_subscription.isExpired) {
      _subscription.expiryDate = _subscription.expiryDate!
          .add(_subscription.isAnnual ? const Duration(days: 365) : const Duration(days: 30));
    } else {
      _subscription.expiryDate = DateTime.now()
          .add(_subscription.isAnnual ? const Duration(days: 365) : const Duration(days: 30));
    }
    _subscription.isActive = true;
    _subscription.lastPaymentDate = DateTime.now();
    await _persist();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> upgradePlan(PlanType newPlan,
      {int extraSecretaries = 0}) async {
    _subscription.planType = newPlan;
    _subscription.extraSecretariesCount = extraSecretaries;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleAutoRenew() async {
    _subscription.autoRenew = !_subscription.autoRenew;
    await _persist();
    notifyListeners();
  }

  bool canAccess(String feature) {
    if (!isActive) return false;
    switch (feature) {
      case 'products':
      case 'categories':
      case 'clients':
      case 'stock':
      case 'dashboard':
      case 'settings':
      case 'reports':
        return true;
      case 'orders':
      case 'pos':
      case 'invoices':
        return _subscription.planType.index >= PlanType.soloPro.index;
      case 'database_access':
      case 'secretaries':
      case 'supervisors':
      case 'boutique_creation':
        return _subscription.planType.index >= PlanType.soloProDb.index;
      case 'multi_store':
      case 'multi_secretaries':
      case 'multi_supervisors':
        return _subscription.planType.index >= PlanType.soloProMulti.index;
      case 'configuration':
      case 'cloud_backup':
        return _subscription.planType.index >= PlanType.soloProDb.index;
      default:
        return true;
    }
  }

  int get maxSecretaries {
    if (!isActive) return 0;
    if (_subscription.planType == PlanType.soloProDb) {
      return 1 + _subscription.extraSecretariesCount;
    }
    if (_subscription.planType.index >= PlanType.soloProMulti.index) {
      return 4 + _subscription.extraSecretariesCount;
    }
    return 0;
  }

  int get maxSupervisors => maxSecretaries;

  double get currentTotalFee => _subscription.totalFee;

  Future<void> payWithFedaPay({
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    PlanType? upgradeTo,
    int extraSecretaries = 0,
    bool isAnnual = false,
  }) async {
    final targetPlan = upgradeTo ?? _subscription.planType;
    final plan = SubscriptionPlan.fromType(targetPlan);
    final baseFee = isAnnual ? plan.annualFee : plan.monthlyFee;
    final amount = baseFee + (extraSecretaries * plan.extraSecretaryFee);

    final period = isAnnual ? 'Annuel' : 'Mensuel';
    final description =
        'Abonnement Gest-Boutique ${plan.name} ($period) - $customerName';

    final fedaResult = await FedaPayService.createTransaction(
      amount: amount,
      description: description,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );

    if (!fedaResult.success ||
        fedaResult.paymentUrl == null ||
        fedaResult.paymentUrl!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fedaResult.message ?? 'Erreur de paiement'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final txnId = fedaResult.transactionId ?? 0;
    await FedaPayService.openPaymentUrl(fedaResult.paymentUrl!);

    _pendingTransactionId = txnId;
    _pendingPlan = targetPlan;
    _pendingExtraSecretaries = extraSecretaries;
    _pendingIsAnnual = isAnnual;

    if (txnId > 0 && context.mounted) {
      _pollPaymentStatus(context, txnId, targetPlan, extraSecretaries, isAnnual);
    }
  }

  Future<void> checkPendingTransaction() async {
    final txnId = _pendingTransactionId;
    if (txnId == null) return;
    final status = await FedaPayService.checkPaymentStatus(txnId);
    if (status == 'approved') {
      await activateSubscription(
        _pendingPlan ?? PlanType.soloStandard,
        extraSecretaries: _pendingExtraSecretaries,
        isAnnual: _pendingIsAnnual,
      );
    }
    _pendingTransactionId = null;
    _pendingPlan = null;
    _pendingExtraSecretaries = 0;
    _pendingIsAnnual = false;
  }

  void _pollPaymentStatus(BuildContext context, int txnId, PlanType plan,
      int extraSecretaries, bool isAnnual) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentCheckDialog(
        txnId: txnId,
        prov: this,
        planType: plan,
        extraSecretaries: extraSecretaries,
        isAnnual: isAnnual,
      ),
    );
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}

class _PaymentCheckDialog extends StatefulWidget {
  final int txnId;
  final SubscriptionProvider prov;
  final PlanType planType;
  final int extraSecretaries;
  final bool isAnnual;

  const _PaymentCheckDialog({
    required this.txnId,
    required this.prov,
    required this.planType,
    required this.extraSecretaries,
    required this.isAnnual,
  });

  @override
  State<_PaymentCheckDialog> createState() => _PaymentCheckDialogState();
}

class _PaymentCheckDialogState extends State<_PaymentCheckDialog> {
  String _status = 'pending';
  bool _checking = true;
  Timer? _timer;
  int _attempts = 0;
  static const int _maxAttempts = 120;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final status = await FedaPayService.checkPaymentStatus(widget.txnId);
    if (!mounted) return;

    setState(() {
      _attempts++;
      if (status != null) _status = status;
      if (_status == 'approved' ||
          _status == 'declined' ||
          _status == 'canceled' ||
          _attempts >= _maxAttempts) {
        _checking = false;
        _timer?.cancel();
      }
    });

    if (_status == 'approved' && !_checking) {
      widget.prov._pendingTransactionId = null;
      await widget.prov.activateSubscription(
        widget.planType,
        extraSecretaries: widget.extraSecretaries,
        isAnnual: widget.isAnnual,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement activé avec succès !'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    } else if (_status == 'declined' || _status == 'canceled') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Paiement ${_status == 'declined' ? 'refusé' : 'annulé'}. Veuillez réessayer.'),
            backgroundColor: Color(0xFFEF5350),
          ),
        );
      }
    } else if (!_checking && _status != 'approved') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Temps écoulé. Vérifiez le statut dans la page abonnement.'),
            backgroundColor: Color(0xFFFFA726),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _checking
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(
                  _status == 'approved'
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 48,
                  color: _status == 'approved'
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350),
                ),
          const SizedBox(height: 20),
          Text(
            _checking
                ? 'Vérification du paiement...'
                : 'Paiement ${_status == 'approved' ? 'confirmé' : 'non confirmé'}',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _checking
                ? 'Veuillez compléter le paiement dans le navigateur FedaPay.'
                : _status == 'approved'
                    ? 'Votre abonnement est actif.'
                    : 'Le paiement n\'a pas abouti.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          if (_checking)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Vérifier plus tard'),
              ),
            ),
          if (!_checking && _status != 'approved')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}