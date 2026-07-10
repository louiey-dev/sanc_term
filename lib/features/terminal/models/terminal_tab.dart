import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

enum TerminalTabType { serial, pty, ble }

class TerminalTab {
  TerminalTab({required this.id, required this.type, required this.label})
      : terminal = Terminal(),
        controller = TerminalController(),
        focusNode = FocusNode(debugLabel: 'terminal_$id');

  final String id;
  final TerminalTabType type;
  final String label;
  final Terminal terminal;
  final TerminalController controller;

  /// Keyboard focus for this pane's [TerminalView]; lets shortcuts move focus
  /// between panes (e.g. Alt+1/2/3…).
  final FocusNode focusNode;
}
