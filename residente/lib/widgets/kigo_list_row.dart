import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fila de lista editorial: ícono + título/subtítulo + chevron opcional.
/// Unidad visual base del rediseño (dashboard, ajustes, listas).
class KigoListRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const KigoListRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor = AppTheme.primaryOrange,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textDimmed : const Color(0xFF8A8BA8),
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right, color: isDark ? AppTheme.textDimmed : AppTheme.textGrey)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
