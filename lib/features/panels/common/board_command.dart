import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/utils/snackbars.dart';
import 'package:sanc_term/features/connection/providers/board_console_selector.dart';

/// Sends [command] fire-and-forget to the active board console (serial first,
/// then PTY/SSH). Output appears in the terminal pane. Warns if nothing is
/// connected. [terminator] is the line ending (CR by default; ESP-AT wants
/// CRLF). Shared by all device panels.
void sendBoardCommand(
  WidgetRef ref,
  BuildContext context,
  String command, {
  String terminator = '\r',
}) {
  final console = pickBoardConsole(ref);
  if (console == null) {
    showErrorSnackbar(context, 'No connected serial or PTY/SSH pane');
    return;
  }
  console.send('${command.trimRight()}$terminator');
}
