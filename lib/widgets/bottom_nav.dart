import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class BottomNavItem {
  final IconData icon;
  final String label;
  final String route;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class BottomNav extends StatelessWidget {
  final List<BottomNavItem> items;
  final String activeRoute;
  final ValueChanged<String> onRouteChanged;

  const BottomNav({
    super.key,
    required this.items,
    required this.activeRoute,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1E1E36).withValues(alpha: 0.85)
        : AppColors.glassBg;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = activeRoute == item.route;
            return SizedBox(
              width: 60,
              child: InkWell(
                onTap: () => onRouteChanged(item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: context.iconNav,
                        color: isActive
                            ? AppColors.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: context.fontSizeNav,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
