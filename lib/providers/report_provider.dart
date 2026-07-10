import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';
import 'order_provider.dart';

enum ReportPeriod { day, week, month, year }

class ReportData {
  final double revenue;
  final double profit;
  final int orderCount;
  final List<ChartPoint> revenueChart;
  final List<ChartPoint> profitChart;

  ReportData({
    this.revenue = 0,
    this.profit = 0,
    this.orderCount = 0,
    this.revenueChart = const [],
    this.profitChart = const [],
  });

  Map<String, dynamic> toMap() => {
    'revenue': revenue,
    'profit': profit,
    'orderCount': orderCount,
    'revenueChart': revenueChart
        .map((c) => {'label': c.label, 'value': c.value})
        .toList(),
    'profitChart': profitChart
        .map((c) => {'label': c.label, 'value': c.value})
        .toList(),
  };

  factory ReportData.fromMap(Map<String, dynamic> map) => ReportData(
    revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
    profit: (map['profit'] as num?)?.toDouble() ?? 0,
    orderCount: map['orderCount'] as int? ?? 0,
    revenueChart:
        (map['revenueChart'] as List?)
            ?.map(
              (c) => ChartPoint(
                c['label'] as String? ?? '',
                (c['value'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList() ??
        [],
    profitChart:
        (map['profitChart'] as List?)
            ?.map(
              (c) => ChartPoint(
                c['label'] as String? ?? '',
                (c['value'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList() ??
        [],
  );
}

class ChartPoint {
  final String label;
  final double value;
  ChartPoint(this.label, this.value);
}

class ReportProvider extends ChangeNotifier {
  final OrderProvider _orderProvider;
  final DatabaseService _db;
  final SyncService _sync;
  ReportPeriod _selectedPeriod = ReportPeriod.day;
  ReportData? _data;

  ReportProvider(this._orderProvider, this._db, this._sync);

  ReportPeriod get selectedPeriod => _selectedPeriod;
  ReportData? get data => _data;

  void setPeriod(ReportPeriod period) {
    _selectedPeriod = period;
    _computeFromLoadedOrders();
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    final key = _reportKey(_selectedPeriod, now);
    final saved = await _db.loadReport(key);
    if (saved != null) {
      _data = ReportData.fromMap(saved);
      notifyListeners();
    }
    await _orderProvider.loadOrdersWithItems();
    _computeFromLoadedOrders();
  }

  String _reportKey(ReportPeriod period, DateTime now) {
    switch (period) {
      case ReportPeriod.day:
        return 'daily_${DateFormat('yyyyMMdd').format(now)}';
      case ReportPeriod.week:
        return 'weekly_${DateFormat("yyyy'_W'ww").format(now)}';
      case ReportPeriod.month:
        return 'monthly_${DateFormat('yyyyMM').format(now)}';
      case ReportPeriod.year:
        return 'yearly_${DateFormat('yyyy').format(now)}';
    }
  }

  void _computeFromLoadedOrders() {
    final allOrders = _orderProvider.orders;
    final now = DateTime.now();

    final orders = allOrders
        .where((o) => o.status == OrderStatus.completed)
        .toList();

    List<Order> filtered;
    List<DateTime> buckets;

    switch (_selectedPeriod) {
      case ReportPeriod.day:
        filtered = orders.where((o) => _isSameDay(o.createdAt, now)).toList();
        buckets = _generateDayBuckets(now);
      case ReportPeriod.week:
        filtered = orders.where((o) => _isSameWeek(o.createdAt, now)).toList();
        buckets = _generateWeekBuckets(now);
      case ReportPeriod.month:
        filtered = orders.where((o) => _isSameMonth(o.createdAt, now)).toList();
        buckets = _generateMonthBuckets(now);
      case ReportPeriod.year:
        filtered = orders.where((o) => _isSameYear(o.createdAt, now)).toList();
        buckets = _generateYearBuckets(now);
    }

    final revenue = filtered.fold(0.0, (sum, o) => sum + o.total);
    final profit = filtered.fold(0.0, (sum, o) => sum + o.totalProfit);
    final orderCount = filtered.length;

    final revenueChart = buckets.map((b) {
      final periodOrders = filtered
          .where((o) => _isInBucket(o.createdAt, b, _selectedPeriod))
          .toList();
      final val = periodOrders.fold(0.0, (s, o) => s + o.total);
      return ChartPoint(_formatBucket(b, _selectedPeriod), val);
    }).toList();

    final profitChart = buckets.map((b) {
      final periodOrders = filtered
          .where((o) => _isInBucket(o.createdAt, b, _selectedPeriod))
          .toList();
      final val = periodOrders.fold(0.0, (s, o) => s + o.totalProfit);
      return ChartPoint(_formatBucket(b, _selectedPeriod), val);
    }).toList();

    _data = ReportData(
      revenue: revenue,
      profit: profit,
      orderCount: orderCount,
      revenueChart: revenueChart,
      profitChart: profitChart,
    );
    notifyListeners();
    _saveCurrentReport();
  }

  void _saveCurrentReport() {
    if (_data == null) return;
    final now = DateTime.now();
    final key = _reportKey(_selectedPeriod, now);
    _db.saveReport(key, _data!.toMap());
    _sync.syncReport(key, _data!.toMap());
  }

  Future<void> saveAllReports() async {
    await _orderProvider.loadOrdersWithItems();
    final allOrders = _orderProvider.orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final now = DateTime.now();

    await _saveSingleReport(
      allOrders,
      now,
      'daily',
      ReportPeriod.day,
      DateFormat('yyyyMMdd').format(now),
    );
    await _saveSingleReport(
      allOrders,
      now,
      'weekly',
      ReportPeriod.week,
      '${DateFormat('yyyy').format(now)}_${now.weekday}',
    );
    await _saveSingleReport(
      allOrders,
      now,
      'monthly',
      ReportPeriod.month,
      DateFormat('yyyyMM').format(now),
    );
    await _saveSingleReport(
      allOrders,
      now,
      'yearly',
      ReportPeriod.year,
      DateFormat('yyyy').format(now),
    );

    _selectedPeriod = ReportPeriod.day;
    _computeFromLoadedOrders();
  }

  Future<void> _saveSingleReport(
    List<Order> allOrders,
    DateTime now,
    String prefix,
    ReportPeriod period,
    String suffix,
  ) async {
    final key = '${prefix}_$suffix';
    List<Order> filtered;
    List<DateTime> buckets;

    switch (period) {
      case ReportPeriod.day:
        filtered = allOrders
            .where((o) => _isSameDay(o.createdAt, now))
            .toList();
        buckets = _generateDayBuckets(now);
      case ReportPeriod.week:
        filtered = allOrders
            .where((o) => _isSameWeek(o.createdAt, now))
            .toList();
        buckets = _generateWeekBuckets(now);
      case ReportPeriod.month:
        filtered = allOrders
            .where((o) => _isSameMonth(o.createdAt, now))
            .toList();
        buckets = _generateMonthBuckets(now);
      case ReportPeriod.year:
        filtered = allOrders
            .where((o) => _isSameYear(o.createdAt, now))
            .toList();
        buckets = _generateYearBuckets(now);
    }

    final revenue = filtered.fold(0.0, (sum, o) => sum + o.total);
    final profit = filtered.fold(0.0, (sum, o) => sum + o.totalProfit);
    final orderCount = filtered.length;

    final revenueChart = buckets.map((b) {
      final val = filtered
          .where((o) => _isInBucket(o.createdAt, b, period))
          .fold(0.0, (s, o) => s + o.total);
      return ChartPoint(_formatBucket(b, period), val);
    }).toList();

    final profitChart = buckets.map((b) {
      final val = filtered
          .where((o) => _isInBucket(o.createdAt, b, period))
          .fold(0.0, (s, o) => s + o.totalProfit);
      return ChartPoint(_formatBucket(b, period), val);
    }).toList();

    final data = ReportData(
      revenue: revenue,
      profit: profit,
      orderCount: orderCount,
      revenueChart: revenueChart,
      profitChart: profitChart,
    );
    await _db.saveReport(key, data.toMap());
    _sync.syncReport(key, data.toMap());
  }

  bool _isSameDay(DateTime? dt, DateTime now) {
    if (dt == null) return false;
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isSameWeek(DateTime? dt, DateTime now) {
    if (dt == null) return false;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !dt.isBefore(startOfWeek) && dt.isBefore(endOfWeek);
  }

  bool _isSameMonth(DateTime? dt, DateTime now) {
    if (dt == null) return false;
    return dt.year == now.year && dt.month == now.month;
  }

  bool _isSameYear(DateTime? dt, DateTime now) {
    if (dt == null) return false;
    return dt.year == now.year;
  }

  bool _isInBucket(DateTime? dt, DateTime bucketStart, ReportPeriod period) {
    if (dt == null) return false;
    switch (period) {
      case ReportPeriod.day:
        return dt.hour >= bucketStart.hour && dt.hour < bucketStart.hour + 1;
      case ReportPeriod.week:
        return _isSameDay(dt, bucketStart);
      case ReportPeriod.month:
        return !dt.isBefore(bucketStart) &&
            dt.isBefore(bucketStart.add(const Duration(days: 7)));
      case ReportPeriod.year:
        return _isSameMonth(dt, bucketStart);
    }
  }

  List<DateTime> _generateDayBuckets(DateTime now) {
    return List.generate(24, (i) => DateTime(now.year, now.month, now.day, i));
  }

  List<DateTime> _generateWeekBuckets(DateTime now) {
    final start = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<DateTime> _generateMonthBuckets(DateTime now) {
    final start = now.subtract(Duration(days: now.day - 1));
    final weeks = ((DateTime(now.year, now.month + 1, 0).day - 1) ~/ 7) + 1;
    return List.generate(weeks, (i) => start.add(Duration(days: i * 7)));
  }

  List<DateTime> _generateYearBuckets(DateTime now) {
    return List.generate(12, (i) => DateTime(now.year, i + 1, 1));
  }

  String _formatBucket(DateTime dt, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.day:
        return '${dt.hour}h';
      case ReportPeriod.week:
        return DateFormat('EEE', 'fr').format(dt);
      case ReportPeriod.month:
        return 'S${(dt.day ~/ 7) + 1}';
      case ReportPeriod.year:
        return DateFormat('MMM', 'fr').format(dt);
    }
  }

  double get totalProfit {
    return _orderProvider.orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (s, o) => s + o.totalProfit);
  }

  Future<String> generateReportText() async {
    if (_data == null) return '';
    final buf = StringBuffer();
    final nf = NumberFormat.currency(
      locale: 'fr',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final periodLabels = {
      ReportPeriod.day: 'Jour',
      ReportPeriod.week: 'Semaine',
      ReportPeriod.month: 'Mois',
      ReportPeriod.year: 'Année',
    };

    buf.writeln('=== RAPPORT DE VENTES ===');
    buf.writeln('Période: ${periodLabels[_selectedPeriod]}');
    buf.writeln(
      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );
    buf.writeln('');
    buf.writeln('Chiffre d\'affaires: ${nf.format(_data!.revenue)}');
    buf.writeln('Bénéfice: ${nf.format(_data!.profit)}');
    buf.writeln('Commandes: ${_data!.orderCount}');
    buf.writeln('');
    buf.writeln('--- Évolution ---');
    for (var i = 0; i < _data!.revenueChart.length; i++) {
      buf.writeln(
        '${_data!.revenueChart[i].label}: ${nf.format(_data!.revenueChart[i].value)} (CA) / ${nf.format(_data!.profitChart[i].value)} (Bénéfice)',
      );
    }
    return buf.toString();
  }
}
