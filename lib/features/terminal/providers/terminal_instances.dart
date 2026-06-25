import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/features/terminal/models/terminal_tab.dart';

part 'terminal_instances.g.dart';

@Riverpod(keepAlive: true)
class TerminalTabsNotifier extends _$TerminalTabsNotifier {
  int _serialCount = 1;
  int _ptyCount = 1;

  @override
  List<TerminalTab> build() => [
        TerminalTab(id: 'serial_0', type: TerminalTabType.serial, label: 'SERIAL'),
        TerminalTab(id: 'pty_0', type: TerminalTabType.pty, label: 'PTY'),
      ];

  void addSerial() {
    _serialCount++;
    state = [
      ...state,
      TerminalTab(
        id: 'serial_${DateTime.now().millisecondsSinceEpoch}',
        type: TerminalTabType.serial,
        label: 'SERIAL $_serialCount',
      ),
    ];
  }

  void addPty() {
    _ptyCount++;
    state = [
      ...state,
      TerminalTab(
        id: 'pty_${DateTime.now().millisecondsSinceEpoch}',
        type: TerminalTabType.pty,
        label: 'PTY $_ptyCount',
      ),
    ];
  }

  void removeTab(String id) {
    if (state.length <= 1) return;
    state = state.where((t) => t.id != id).toList();
  }
}
