import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;

  const TopBar({super.key, required this.title, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = context.isMobile;
    final settings = context.watch<SettingsProvider>();

    final bgColor = isDark ? const Color(0xFF16162A) : AppColors.glassBg;

    return Container(
      height: isMobile ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuTap,
              color: onSurfaceDim,
            ),
          if (onMenuTap != null) SizedBox(width: isMobile ? 4 : 8),
          _buildLogo(settings),
          if (settings.logoBase64 != null) const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: context.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: context.iconSm,
            ),
            onPressed: () => context.read<SettingsProvider>().toggleDarkMode(),
            color: onSurfaceDim,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(SettingsProvider settings) {
    if (settings.logoBase64 == null) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(settings.logoBase64!);
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
