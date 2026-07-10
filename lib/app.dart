import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/subscription_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/subscription/force_subscription_screen.dart';
import 'screens/subscription/subscription_screen.dart';

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
      home: auth.status == AuthStatus.authenticated
          ? Consumer<SubscriptionProvider>(
              builder: (ctx, subProv, _) {
                if (!subProv.initialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                return subProv.isActive
                    ? const HomeScreen()
                    : ForceSubscriptionScreen(key: UniqueKey());
              },
            )
          : const LoginScreen(),
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}