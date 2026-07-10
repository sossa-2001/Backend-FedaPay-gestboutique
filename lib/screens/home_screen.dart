import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/responsive.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../widgets/drawer_menu.dart';
import 'dashboard/dashboard_screen.dart';
import 'clients/clients_screen.dart';
import 'products/products_screen.dart';
import 'reports/reports_screen.dart';
import 'stock/stock_screen.dart';
import 'pos/pos_screen.dart';
import 'invoices/invoices_screen.dart';
import 'settings/settings_screen.dart';
import 'subscription/subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeRoute = '/dashboard';
  bool _sidebarExpanded = true;

  List<SidebarItem> _navItems(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    final isGuest = !auth.isLoggedIn;
    return [
      if (isGuest || auth.hasPermission('dashboard'))
        SidebarItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          route: '/dashboard',
        ),
      if (isGuest || (auth.hasPermission('products') && sub.canAccess('products')))
        SidebarItem(
          icon: Icons.inventory_2_rounded,
          label: 'Produits',
          route: '/products',
        ),
      if (isGuest || (auth.hasPermission('clients') && sub.canAccess('clients')))
        SidebarItem(
          icon: Icons.people_rounded,
          label: 'Clients',
          route: '/clients',
        ),
      if (isGuest || (auth.hasPermission('reports') && sub.canAccess('reports')))
        SidebarItem(
          icon: Icons.bar_chart_rounded,
          label: 'Rapports',
          route: '/reports',
        ),
      if (isGuest || (auth.hasPermission('stock') && sub.canAccess('stock')))
        SidebarItem(
          icon: Icons.swap_vert_rounded,
          label: 'Stock',
          route: '/stock',
        ),
      if (isGuest || (auth.hasPermission('pos') && sub.canAccess('pos')))
        SidebarItem(
          icon: Icons.point_of_sale_rounded,
          label: 'Vendre',
          route: '/pos',
        ),
      if (isGuest || (auth.hasPermission('orders') && sub.canAccess('orders')))
        SidebarItem(
          icon: Icons.description_rounded,
          label: 'Factures',
          route: '/invoices',
        ),
      if (isGuest || (auth.hasPermission('settings') && sub.canAccess('settings')))
        SidebarItem(
          icon: Icons.settings_rounded,
          label: 'Paramètres',
          route: '/settings',
        ),
    ];
  }

  final Map<String, String> _routeTitles = {
    '/dashboard': 'Tableau de bord',
    '/products': 'Produits',
    '/clients': 'Clients',
    '/reports': 'Rapports',
    '/stock': 'Mouvements de stock',
    '/pos': 'Point de vente',
    '/invoices': 'Factures',
    '/settings': 'Paramètres',
  };

  String _title(String fallback) => _routeTitles[_activeRoute] ?? fallback;

  Widget get _currentScreen {
    switch (_activeRoute) {
      case '/dashboard':
        return const DashboardScreen();
      case '/products':
        return const ProductsScreen();
      case '/clients':
        return const ClientsScreen();
      case '/reports':
        return const ReportsScreen();
      case '/stock':
        return const StockScreen();
      case '/pos':
        return const PosScreen();
      case '/invoices':
        return const InvoicesScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sidebarExpanded = context.isDesktop;
  }

  @override
  Widget build(BuildContext context) {
    final companyName = context.select<SettingsProvider, String>(
      (s) => s.companyName,
    );
    final sub = context.watch<SubscriptionProvider>();

    if (context.isDesktop) {
      return _buildDesktopLayout(companyName, sub);
    }
    return _buildMobileLayout(companyName, sub);
  }

  Widget _subscriptionBanner(SubscriptionProvider sub) {
    if (!sub.isActive) return const SizedBox.shrink();

    final s = sub.subscription;
    if (s.isExpiringSoon) {
      final remaining = s.daysRemaining;
      final label = remaining > 0
          ? 'Abonnement expire dans $remaining jour${remaining > 1 ? 's' : ''}'
          : s.expiryDate != null
              ? 'Abonnement expire dans ${s.expiryDate!.difference(DateTime.now()).inMinutes} min'
              : 'Abonnement expire bientôt';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Renouveler', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMobileLayout(String companyName, SubscriptionProvider sub) {
    return Scaffold(
      drawer: DrawerMenu(
        items: _navItems(context)
            .map(
              (n) =>
                  DrawerMenuItem(icon: n.icon, label: n.label, route: n.route),
            )
            .toList(),
        activeRoute: _activeRoute,
        onRouteChanged: (route) {
          setState(() => _activeRoute = route);
        },
        companyName: companyName,
      ),
      body: Builder(
        builder: (ctx) => SafeArea(
          child: Column(
            children: [
              TopBar(
                title: _title(companyName),
                onMenuTap: () => Scaffold.of(ctx).openDrawer(),
              ),
              _subscriptionBanner(sub),
              Expanded(child: _currentScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(String companyName, SubscriptionProvider sub) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            items: _navItems(context),
            activeRoute: _activeRoute,
            isExpanded: _sidebarExpanded,
            onToggle: (v) => setState(() => _sidebarExpanded = v),
            onRouteChanged: (route) => setState(() => _activeRoute = route),
            companyName: companyName,
          ),
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      TopBar(
                        title: _title(companyName),
                        onMenuTap: () =>
                            setState(() => _sidebarExpanded = !_sidebarExpanded),
                      ),
                      _subscriptionBanner(sub),
                      Expanded(child: _currentScreen),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
