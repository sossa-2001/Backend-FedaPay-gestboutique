import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../home_screen.dart';

class StorePickerScreen extends StatelessWidget {
  const StorePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une boutique')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: auth.availableStores.length,
        itemBuilder: (context, index) {
          final store = auth.availableStores[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: const Icon(
                Icons.store_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              title: Text(
                store.storeName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Cliquez pour accéder'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await auth.selectStore(store);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
