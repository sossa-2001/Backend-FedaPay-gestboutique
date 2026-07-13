import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/order.dart';
import '../../models/subscription_plan.dart';
import '../../utils/responsive.dart';
import '../subscription/subscription_screen.dart';
import '../subscription/activation_code_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _subDialogShown = false;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionProvider>().addListener(_onSubChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscription());
  }

  @override
  void dispose() {
    context.read<SubscriptionProvider>().removeListener(_onSubChanged);
    super.dispose();
  }

  void _onSubChanged() {
    if (!mounted) return;
    final sub = context.read<SubscriptionProvider>();
    if (sub.isActive && _subDialogShown) {
      _subDialogShown = false;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!sub.isActive && !_subDialogShown) {
      _checkSubscription();
    }
  }

  void _checkSubscription() {
    if (!mounted || _subDialogShown) return;
    final sub = context.read<SubscriptionProvider>();
    if (sub.subscription.isExpired) {
      _subDialogShown = true;
      _showExpiredDialog();
    } else if (sub.subscription.isExpiringSoon) {
      _subDialogShown = true;
      _showExpiringSoonDialog(sub);
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Abonnement expiré', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Votre abonnement a expiré. Choisissez un plan pour continuer à utiliser l\'application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...SubscriptionPlan.plans.map((plan) => _buildPlanCard(plan)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActivationCodeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: const Text('J\'ai un code d\'activation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExpiringSoonDialog(SubscriptionProvider sub) {
    final s = sub.subscription;
    final remaining = s.daysRemaining;
    final label = remaining > 0
        ? '$remaining jour${remaining > 1 ? 's' : ''}'
        : '${s.expiryDate!.difference(DateTime.now()).inMinutes} min';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.access_time_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Abonnement bientôt expiré', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Il vous reste $label.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...SubscriptionPlan.plans.map((plan) => _buildPlanCard(plan)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final currencyFmt = NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscriptionScreen(initialPlan: plan)),
          );
          if (mounted) {
            _subDialogShown = false;
            _checkSubscription();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  plan.type == PlanType.soloStandard
                      ? Icons.person_rounded
                      : plan.type == PlanType.soloPro
                          ? Icons.star_rounded
                          : plan.type == PlanType.soloProDb
                              ? Icons.cloud_rounded
                              : Icons.devices_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${currencyFmt.format(plan.monthlyFee)}/mois',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final isWide = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aperçu de votre activité',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            children: [
              StatCard(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                value: NumberFormat.currency(
                  locale: 'fr',
                  symbol: 'FCFA',
                  decimalDigits: 0,
                ).format(orderProvider.totalRevenue),
                title: 'Revenu total',
                percentage: 12.5,
                isUp: true,
                sparklineData: [
                  FlSpot(0, 100),
                  FlSpot(1, 200),
                  FlSpot(2, 150),
                  FlSpot(3, 300),
                  FlSpot(4, 250),
                  FlSpot(5, 400),
                ],
              ),
              StatCard(
                icon: Icons.inventory_2_rounded,
                iconColor: AppColors.warning,
                iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                value: '${productProvider.products.length}',
                title: 'Produits',
                percentage: 8.3,
                isUp: true,
                sparklineData: [
                  FlSpot(0, 50),
                  FlSpot(1, 60),
                  FlSpot(2, 55),
                  FlSpot(3, 70),
                  FlSpot(4, 65),
                  FlSpot(5, 80),
                ],
              ),
              StatCard(
                icon: Icons.shopping_cart_rounded,
                iconColor: AppColors.success,
                iconBgColor: AppColors.success.withValues(alpha: 0.1),
                value: '${orderProvider.todayOrderCount}',
                title: 'Ventes aujourd\'hui',
                percentage: -3.2,
                isUp: false,
                sparklineData: [
                  FlSpot(0, 30),
                  FlSpot(1, 25),
                  FlSpot(2, 35),
                  FlSpot(3, 20),
                  FlSpot(4, 28),
                  FlSpot(5, 15),
                ],
              ),
              StatCard(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
                iconBgColor: AppColors.error.withValues(alpha: 0.1),
                value: '${productProvider.lowStockCount}',
                title: 'Stock faible',
                percentage: 5.0,
                isUp: true,
                sparklineData: [
                  FlSpot(0, 8),
                  FlSpot(1, 6),
                  FlSpot(2, 10),
                  FlSpot(3, 7),
                  FlSpot(4, 5),
                  FlSpot(5, 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (productProvider.lowStockCount + productProvider.outOfStockCount >
              0)
            _buildStockAlerts(context, productProvider),
          if (productProvider.lowStockCount + productProvider.outOfStockCount >
              0)
            const SizedBox(height: 24),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildRevenueChart(context, orderProvider),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildRecentOrders(context, orderProvider),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildRevenueChart(context, orderProvider),
                const SizedBox(height: 16),
                _buildRecentOrders(context, orderProvider),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStockAlerts(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final alerts =
        productProvider.products
            .where(
              (p) =>
                  p.stockQuantity <= 0 ||
                  (p.minStock != null && p.stockQuantity <= p.minStock!),
            )
            .toList()
          ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: context.iconSm,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertes stock',
                style: TextStyle(
                  fontSize: context.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alerts.length}',
                  style: TextStyle(
                    fontSize: context.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((product) {
            final isOutOfStock = product.stockQuantity <= 0;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOutOfStock ? AppColors.error : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: context.fontSizeMd,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOutOfStock
                          ? 'Rupture'
                          : '${product.stockQuantity.toStringAsFixed(0)} / ${product.minStock!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, OrderProvider orderProvider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final currencyFmt = NumberFormat.currency(
      locale: 'fr',
      symbol: '',
      decimalDigits: 0,
    );

    final spots = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
      final total = orderProvider.orders
          .where(
            (o) =>
                o.status == OrderStatus.completed &&
                o.createdAt != null &&
                o.createdAt!.isAfter(
                  dayStart.subtract(const Duration(seconds: 1)),
                ) &&
                o.createdAt!.isBefore(dayEnd),
          )
          .fold(0.0, (sum, o) => sum + o.total);
      return FlSpot(i.toDouble(), total);
    });

    final maxY = spots.fold(0.0, (max, s) => s.y > max ? s.y : max);
    final interval = maxY > 0
        ? (maxY / 4).ceilToDouble().clamp(1, double.infinity)
        : 100;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus',
            style: TextStyle(
              fontSize: context.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Évolution des 7 derniers jours',
            style: TextStyle(fontSize: context.fontSizeSm, color: onSurfaceDim),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval.toDouble(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          currencyFmt.format(value),
                          style: TextStyle(
                            fontSize: context.fontSizeCaption,
                            color: onSurfaceDim,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= 7) return const SizedBox();
                        final day = today.subtract(Duration(days: 6 - idx));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayNames[day.weekday % 7],
                            style: TextStyle(
                              fontSize: context.fontSizeCaption,
                              color: onSurfaceDim,
                            ),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context, OrderProvider orderProvider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernières commandes',
            style: TextStyle(
              fontSize: context.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...orderProvider.orders.take(5).map((order) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: order.status == OrderStatus.completed
                          ? AppColors.success.withValues(alpha: 0.1)
                          : order.status == OrderStatus.pending
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.status == OrderStatus.completed
                          ? 'Terminée'
                          : order.status == OrderStatus.pending
                          ? 'En attente'
                          : 'Annulée',
                      style: TextStyle(
                        fontSize: context.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: order.status == OrderStatus.completed
                            ? AppColors.success
                            : order.status == OrderStatus.pending
                            ? AppColors.warning
                            : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    NumberFormat.currency(
                      locale: 'fr',
                      symbol: 'FCFA',
                      decimalDigits: 0,
                    ).format(order.total),
                    style: TextStyle(
                      fontSize: context.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
