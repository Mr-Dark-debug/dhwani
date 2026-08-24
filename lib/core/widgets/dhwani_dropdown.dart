import 'package:flutter/material.dart';
import '../../app/theme/dhwani_theme.dart';

class DhwaniDropdownItem<T> {
  const DhwaniDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.trailing,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Widget? trailing;
}

class DhwaniDropdown<T> extends StatelessWidget {
  const DhwaniDropdown({
    super.key,
    required this.items,
    required this.onSelected,
    this.value,
    this.label,
    this.icon,
    this.tooltip,
    this.isPill = true,
    this.compact = false,
  });

  final T? value;
  final List<DhwaniDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? label;
  final IconData? icon;
  final String? tooltip;
  final bool isPill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF1E1E1C)
        : theme.colorScheme.surface;
    final outlineColor = theme.colorScheme.outline.withValues(alpha: .2);

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: surfaceColor,
          elevation: 8,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: outlineColor, width: 1),
          ),
        ),
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        initialValue: value,
        onSelected: onSelected,
        offset: const Offset(0, 8),
        itemBuilder: (context) => items.map((item) {
          final isSelected = item.value == value;
          return PopupMenuItem<T>(
            value: item.value,
            height: 44,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? DhwaniColors.signal
                        : theme.colorScheme.onSurface.withValues(alpha: .75),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? DhwaniColors.signal
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: DhwaniColors.signal,
                  )
                else if (item.trailing != null)
                  item.trailing!,
              ],
            ),
          );
        }).toList(),
        child: isPill
            ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: .06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: compact ? 16 : 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: .85,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (label != null)
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: compact ? 16 : 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon ?? Icons.more_vert_rounded),
              ),
      ),
    );
  }
}
