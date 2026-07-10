import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final Color? glowColor;
  final double glowOpacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.boxShadow,
    this.glowColor,
    this.glowOpacity = 0.06,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1E1E36).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.7);
    final borderColor = isDark
        ? const Color(0xFF2A2A45)
        : const Color(0xFFE8ECF4);
    final shadow =
        boxShadow ??
        [
          BoxShadow(
            color: (glowColor ?? AppColors.primary).withValues(
              alpha: glowOpacity,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor),
              boxShadow: shadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
