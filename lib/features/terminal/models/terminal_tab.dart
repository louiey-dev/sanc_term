import 'package:xterm/xterm.dart';

enum TerminalTabType { serial, pty }

class TerminalTab {
  TerminalTab({required this.id, required this.type, required this.label})
      : terminal = Terminal(),
        controller = TerminalController();

  final String id;
  final TerminalTabType type;
  final String label;
  final Terminal terminal;
  final TerminalController controller;
}
