import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/models/panel_entry.dart';

class StubPanel extends StatelessWidget {
  final PanelEntry entry;
  const StubPanel({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(entry.icon, size: 48, color: c.muted),
          const SizedBox(height: 16),
          Text(
            entry.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(entry.description, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 24),
          Text(
            'Not yet implemented',
            style: TextStyle(fontSize: 11, color: c.muted),
          ),
        ],
      ),
    );
  }
}
