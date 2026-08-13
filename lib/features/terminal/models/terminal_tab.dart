import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

enum TerminalTabType { serial, pty, ble }

class TerminalTab {
  TerminalTab({
    required this.id,
    required this.type,
    required this.label,
    int maxLines = 10000,
    int pasteCharDelayMs = 0,
    int pasteLineDelayMs = 0,
  }) : terminal = Terminal(maxLines: maxLines),
       controller = TerminalController(),
       focusNode = FocusNode(debugLabel: 'terminal_$id') {
    terminal.pasteCharDelayMs = pasteCharDelayMs;
    terminal.pasteLineDelayMs = pasteLineDelayMs;
  }

  final String id;
  final TerminalTabType type;
  final String label;
  final Terminal terminal;
  final TerminalController controller;

  /// Keyboard focus for this pane's [TerminalView]; lets shortcuts move focus
  /// between panes (e.g. Alt+1/2/3…).
  final FocusNode focusNode;

  /// Sets paste character and line delays on the tab's underlying terminal.
  void setPasteDelay(int charDelayMs, int lineDelayMs) {
    terminal.pasteCharDelayMs = charDelayMs;
    terminal.pasteLineDelayMs = lineDelayMs;
  }
}
