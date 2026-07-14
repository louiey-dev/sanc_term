import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

Widget buildDropdown<T>(
  BuildContext context, {
  T? value,
  String? hint,
  required List<DropdownMenuItem<T>> items,
  ValueChanged<T?>? onChanged,
  double width = 100,
}) {
  final c = context.colors;
  final matchingCount = items.where((item) => item.value == value).length;
  final safeValue = matchingCount == 1 ? value : null;

  return Container(
    height: 32,
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: safeValue,
        hint: hint != null
            ? Text(hint, style: TextStyle(fontSize: 12, color: c.muted))
            : null,
        isExpanded: true,
        dropdownColor: c.card,
        style: TextStyle(fontSize: 12, color: c.foreground),
        icon: Icon(Icons.expand_more, size: 16, color: c.muted),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 20,
      color: context.colors.border,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Consolas',
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? c.muted),
          const SizedBox(height: 6),
        ],
        Text(label, style: TextStyle(fontSize: 11, color: c.muted)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Consolas',
              color: valueColor ?? c.foreground,
            ),
            children: unit != null
                ? [
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.muted,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? c.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// A helper function that returns a customized VerticalDivider.
Widget verticalDivider({
  Color color = Colors.grey,
  double thickness = 1,
  double indent = 8,
  double endIndent = 8,
}) {
  return VerticalDivider(
    color: color,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
  );
}

// You can then use it in a Row like this:
// Row(
//   children: [
//     Text('Item 1'),
//     verticalDivider(),
//     Text('Item 2'),
//   ],
// )
