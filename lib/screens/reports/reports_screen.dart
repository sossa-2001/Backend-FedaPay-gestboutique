import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glassmorphism.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/responsive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final data = reportProvider.data;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final nf = NumberFormat.currency(
      locale: 'fr',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.isMobile ? 12 : 24,
              24,
              context.isMobile ? 12 : 24,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rapports',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyse des ventes et bénéfices',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                if (data != null) ...[
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Partager',
                    color: AppColors.primary,
                    onPressed: () => _shareReport(context, reportProvider),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Télécharger',
                    color: AppColors.primary,
                    onPressed: () => _downloadReport(context, reportProvider),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 12 : 24,
              vertical: 16,
            ),
            child: _buildPeriodSelector(reportProvider),
          ),
          if (data != null)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.isMobile ? 12 : 24,
                  0,
                  context.isMobile ? 12 : 24,
                  24,
                ),
                child: Column(
                  children: [
                    _buildStatsRow(data, nf, isWide),
                    const SizedBox(height: 24),
                    _buildRevenueChart(data, nf),
                    const SizedBox(height: 24),
                    _buildProfitChart(data, nf),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ReportProvider provider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E36).withValues(alpha: 0.85)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : AppColors.border,
        ),
      ),
      child: Row(
        children: ReportPeriod.values.map((period) {
          final isSelected = provider.selectedPeriod == period;
          final labels = {
            ReportPeriod.day: 'Jour',
            ReportPeriod.week: 'Semaine',
            ReportPeriod.month: 'Mois',
            ReportPeriod.year: 'Année',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setPeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[period]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : onSurfaceDim,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(ReportData data, NumberFormat nf, bool isWide) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4,
      ),
      children: [
        _statTile(
          Icons.receipt_long_rounded,
          'Chiffre d\'affaires',
          nf.format(data.revenue),
          AppColors.primary,
        ),
        _statTile(
          Icons.trending_up_rounded,
          'Bénéfice',
          nf.format(data.profit),
          AppColors.success,
        ),
        _statTile(
          Icons.shopping_cart_rounded,
          'Commandes',
          '${data.orderCount}',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    final onSurfaceDim = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: onSurfaceDim)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ReportData data, NumberFormat nf) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chiffre d\'affaires',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: data.revenueChart.every((p) => p.value == 0)
                ? Center(
                    child: Text(
                      'Aucune donnée',
                      style: TextStyle(color: onSurfaceDim),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: onSurfaceDim,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.revenueChart.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data.revenueChart[i].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: onSurfaceDim,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
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
                      barGroups: data.revenueChart.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              color: AppColors.primary,
                              width: isWide ? 24 : 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart(ReportData data, NumberFormat nf) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bénéfice',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: data.profitChart.every((p) => p.value == 0)
                ? Center(
                    child: Text(
                      'Aucune donnée',
                      style: TextStyle(color: onSurfaceDim),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: onSurfaceDim,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.profitChart.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data.profitChart[i].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: onSurfaceDim,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
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
                      barGroups: data.profitChart.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              color: AppColors.success,
                              width: isWide ? 24 : 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
          ),
        ],
      ),
    );
  }

  bool get isWide => MediaQuery.of(context).size.width >= 768;

  Future<void> _shareReport(
    BuildContext context,
    ReportProvider provider,
  ) async {
    final text = await provider.generateReportText();
    if (text.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  Future<void> _downloadReport(
    BuildContext context,
    ReportProvider provider,
  ) async {
    final text = await provider.generateReportText();
    if (text.isEmpty) return;
    final companyName = context.read<SettingsProvider>().companyName;
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Rapport de ventes $companyName'),
    );
  }
}
