import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/subscription_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/subscription/force_subscription_screen.dart';

class GestBoutiqueApp extends StatelessWidget {
  const GestBoutiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<SettingsProvider, bool>(
      (s) => s.isDarkMode,
    );
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Gest-Boutique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _AppLifecycleWrapper(
        child: auth.status == AuthStatus.authenticated
            ? _AuthenticatedArea()
            : const LoginScreen(),
      ),
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}

class _AuthenticatedArea extends StatefulWidget {
  @override
  State<_AuthenticatedArea> createState() => _AuthenticatedAreaState();
}

class _AuthenticatedAreaState extends State<_AuthenticatedArea> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != null) {
      context.read<SubscriptionProvider>().setUserId(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (ctx, subProv, _) {
        if (!subProv.initialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return subProv.isActive
            ? const HomeScreen()
            : ForceSubscriptionScreen(key: UniqueKey());
      },
    );
  }
}

class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SubscriptionProvider>().checkPendingTransaction();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}