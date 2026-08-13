import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/features/terminal/models/terminal_tab.dart';

import 'package:sanc_term/features/terminal/providers/paste_settings_provider.dart';

part 'terminal_instances.g.dart';

/// Whether terminal output is paused. When true, panes (serial, PTY, BLE) stop
/// writing to their terminal view and to the file logger; the underlying I/O and
/// command capture keep running so nothing is actually lost on the wire.
final terminalPausedProvider = StateProvider<bool>((ref) => false);

/// Per-BLE-pane toggle for the `[service/char]` source-id tag on notification
/// lines. On by default (matches the original behavior); turn it off to print
/// raw notification payloads with no id prefix. Keyed by the pane's tab id.
final bleShowSourceIdProvider =
    StateProvider.family<bool, String>((ref, tabId) => true);

@Riverpod(keepAlive: true)
class TerminalTabsNotifier extends _$TerminalTabsNotifier {
  int _serialCount = 1;
  int _ptyCount = 1;
  int _bleCount = 0;

  @override
  List<TerminalTab> build() {
    final pasteSettings = ref.read(pasteSettingsNotifierProvider);
    return [
      TerminalTab(
        id: 'serial_0',
        type: TerminalTabType.serial,
        label: 'SERIAL',
        pasteCharDelayMs: pasteSettings.charDelayMs,
        pasteLineDelayMs: pasteSettings.lineDelayMs,
      ),
      TerminalTab(
        id: 'pty_0',
        type: TerminalTabType.pty,
        label: 'PTY',
        pasteCharDelayMs: pasteSettings.charDelayMs,
        pasteLineDelayMs: pasteSettings.lineDelayMs,
      ),
    ];
  }

  void addSerial() {
    _serialCount++;
    final pasteSettings = ref.read(pasteSettingsNotifierProvider);
    state = [
      ...state,
      TerminalTab(
        id: 'serial_${DateTime.now().millisecondsSinceEpoch}',
        type: TerminalTabType.serial,
        label: 'SERIAL $_serialCount',
        pasteCharDelayMs: pasteSettings.charDelayMs,
        pasteLineDelayMs: pasteSettings.lineDelayMs,
      ),
    ];
  }

  void addPty() {
    _ptyCount++;
    final pasteSettings = ref.read(pasteSettingsNotifierProvider);
    state = [
      ...state,
      TerminalTab(
        id: 'pty_${DateTime.now().millisecondsSinceEpoch}',
        type: TerminalTabType.pty,
        label: 'PTY $_ptyCount',
        pasteCharDelayMs: pasteSettings.charDelayMs,
        pasteLineDelayMs: pasteSettings.lineDelayMs,
      ),
    ];
  }

  void addBle() {
    _bleCount++;
    final pasteSettings = ref.read(pasteSettingsNotifierProvider);
    state = [
      ...state,
      TerminalTab(
        id: 'ble_${DateTime.now().millisecondsSinceEpoch}',
        type: TerminalTabType.ble,
        label: _bleCount == 1 ? 'BLE DATA' : 'BLE DATA $_bleCount',
        pasteCharDelayMs: pasteSettings.charDelayMs,
        pasteLineDelayMs: pasteSettings.lineDelayMs,
      ),
    ];
  }

  void removeTab(String id) {
    if (state.length <= 1) return;
    state = state.where((t) => t.id != id).toList();
  }
}

@Riverpod(keepAlive: true)
class ActiveTabId extends _$ActiveTabId {
  @override
  String? build() => null;

  void setActive(String? id) => state = id;
}

