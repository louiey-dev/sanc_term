import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

class NotFoundPanel extends StatelessWidget {
  final String panelId;
  const NotFoundPanel({super.key, required this.panelId});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: c.destructive),
          const SizedBox(height: 16),
          Text(
            "Unknown panel: '$panelId'",
            style: TextStyle(color: c.muted),
          ),
        ],
      ),
    );
  }
}
