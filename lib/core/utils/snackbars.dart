import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

void showSnackbar(BuildContext context, String msg, {int durationMs = 1000}) {
  final c = context.colors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: durationMs),
      content: Text(msg),
      backgroundColor: c.primary,
      action: SnackBarAction(
        label: 'OK',
        textColor: c.primaryForeground,
        onPressed: () {},
      ),
    ),
  );
}

void showErrorSnackbar(BuildContext context, String msg, {int durationMs = 2000}) {
  final c = context.colors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: durationMs),
      content: Text(msg),
      backgroundColor: c.destructive,
      action: SnackBarAction(
        label: 'OK',
        textColor: c.foreground,
        onPressed: () {},
      ),
    ),
  );
}
