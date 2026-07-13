import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/database_factory.dart';
import 'providers/category_provider.dart';
import 'providers/client_provider.dart';
import 'providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/order_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/sync_service.dart';
import 'l10n/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  Widget? _app;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final db = createDatabaseService();
      await db.init();

      final syncService = SyncService(db);
      await syncService.init();

      final firestore = FirebaseFirestore.instance;
      final authProvider = AuthProvider(db, firestore, syncService);
      await authProvider.init();

      final categoryProvider = CategoryProvider(db, syncService);
      final clientProvider = ClientProvider(db, syncService);
      final productProvider = ProductProvider(db, syncService);
      final stockProvider = StockProvider(db, productProvider, syncService);
      final orderProvider = OrderProvider(db, syncService);
      final posProvider = PosProvider(orderProvider, stockProvider);
      final reportProvider = ReportProvider(orderProvider, db, syncService);
      final settingsProvider = SettingsProvider(db, syncService);
      final localeProvider = LocaleProvider(db);
      await localeProvider.load();
      final syncProvider = SyncProvider(syncService, authProvider);
      final subscriptionProvider = SubscriptionProvider(
        db, firestore, authProvider.currentUserId,
      );
      await subscriptionProvider.init();

      await categoryProvider.loadCategories();
      await clientProvider.loadClients();
      await productProvider.loadProducts();
      await stockProvider.loadMovements();
      await orderProvider.loadOrdersWithItems();
      await settingsProvider.load();

      authProvider.onSyncComplete = () async {
        await categoryProvider.loadCategories();
        await clientProvider.loadClients();
        await productProvider.loadProducts();
        await stockProvider.loadMovements();
        await orderProvider.loadOrdersWithItems();
      };

      syncService.onPullComplete = () async {
        await categoryProvider.loadCategories();
        await clientProvider.loadClients();
        await productProvider.loadProducts();
        await stockProvider.loadMovements();
        await orderProvider.loadOrdersWithItems();
      };

      if (authProvider.isLoggedIn) {
        syncProvider.triggerSync();
      }

      if (!mounted) return;
      setState(
        () => _app = MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: categoryProvider),
            ChangeNotifierProvider.value(value: clientProvider),
            ChangeNotifierProvider.value(value: productProvider),
            ChangeNotifierProvider.value(value: stockProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: posProvider),
            ChangeNotifierProvider.value(value: reportProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: syncProvider),
            ChangeNotifierProvider.value(value: subscriptionProvider),
            ChangeNotifierProvider.value(value: localeProvider),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const GestBoutiqueApp(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _app = _ErrorScreen(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _app ??
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen(this.error);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Color(0xFFEF5350),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
