import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class AppDataColumn {
  final String label;
  final double flex;
  final TextAlign? textAlign;

  const AppDataColumn({required this.label, this.flex = 1, this.textAlign});
}

class AppDataRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? statusColor;
  final String? statusLabel;

  AppDataRow({
    required this.cells,
    this.onTap,
    this.statusColor,
    this.statusLabel,
  });
}

class DataTableWidget extends StatelessWidget {
  final List<AppDataColumn> columns;
  final List<AppDataRow> rows;
  final double? rowHeight;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF1E1E36).withValues(alpha: 0.85)
        : AppColors.card;
    final headerBg = isDark ? const Color(0xFF16162A) : AppColors.background;
    final borderColor = isDark ? const Color(0xFF2A2A45) : AppColors.border;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  flex: col.flex.toInt(),
                  child: Text(
                    col.label,
                    style: TextStyle(
                      fontSize: context.fontSizeSm,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceDim,
                    ),
                    textAlign: col.textAlign ?? TextAlign.start,
                  ),
                );
              }).toList(),
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return InkWell(
              onTap: row.onTap,
              child: Container(
                height: rowHeight ?? 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ...row.cells.asMap().entries.map((cellEntry) {
                      final cellIndex = cellEntry.key;
                      return Expanded(
                        flex: columns[cellIndex].flex.toInt(),
                        child: cellEntry.value,
                      );
                    }),
                    if (row.statusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (row.statusColor ?? AppColors.primary)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          row.statusLabel!,
                          style: TextStyle(
                            fontSize: context.fontSizeSm,
                            fontWeight: FontWeight.w600,
                            color: row.statusColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
