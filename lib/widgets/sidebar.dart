import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class Sidebar extends StatefulWidget {
  final List<SidebarItem> items;
  final String activeRoute;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onRouteChanged;
  final String companyName;

  const Sidebar({
    super.key,
    required this.items,
    required this.activeRoute,
    required this.isExpanded,
    required this.onToggle,
    required this.onRouteChanged,
    this.companyName = 'Gest-Boutique',
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnim = Tween<double>(begin: 72, end: 240).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, child) {
        final width = _widthAnim.value;
        final isExpanded = width > 150;
        return Container(
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF12122A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            border: Border(
              right: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 20 : 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.dark],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fontSizeXl,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.companyName,
                        style: TextStyle(
                          fontSize: context.fontSizeLg,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 12 : 8,
                    vertical: 8,
                  ),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isActive = widget.activeRoute == item.route;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isExpanded ? 4 : 2),
                      child: Tooltip(
                        message: isExpanded ? '' : item.label,
                        preferBelow: false,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onRouteChanged(item.route),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              padding: EdgeInsets.symmetric(
                                horizontal: isExpanded ? 12 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  if (!isExpanded)
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    item.icon,
                                    size: context.iconNav,
                                    color: isActive
                                        ? AppColors.primary
                                        : onSurface.withValues(alpha: 0.6),
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: context.fontSizeMd,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isActive
                                            ? AppColors.primary
                                            : onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isActive)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
