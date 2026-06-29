import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/connection/providers/board_console.dart';
import 'package:sanc_term/features/connection/providers/serial_pane_provider.dart';
import 'package:sanc_term/features/terminal/models/terminal_tab.dart';
import 'package:sanc_term/features/terminal/providers/terminal_instances.dart';

/// A [BoardConsole] backed by a connected SERIAL pane.
class SerialBoardConsole implements BoardConsole {
  SerialBoardConsole({required this.id, required this.notifier});

  @override
  final String id;
  final SerialPaneNotifier notifier;

  @override
  ConsoleKind get kind => ConsoleKind.serial;

  @override
  bool get isConnected => notifier.isConnected;

  @override
  Future<String> run(
    String command, {
    Duration timeout = const Duration(seconds: 4),
  }) =>
      notifier.runCommand(command, timeout: timeout);

  @override
  void send(String data) => notifier.send(data);
}

/// Picks the console to run board commands on, by priority:
///   1. the active/selected SERIAL pane (if connected);
///   2. otherwise the first connected SERIAL pane;
///   3. otherwise a connected PTY pane (where the user may have SSH'd in);
///   4. otherwise null — the caller should warn that nothing is connected.
BoardConsole? pickBoardConsole(WidgetRef ref) {
  final activeId = ref.read(activeTabIdProvider);

  // 1. Try the active/selected tab first (whether Serial or PTY)
  if (activeId != null) {
    final tabs = ref.read(terminalTabsNotifierProvider);
    TerminalTab? activeTab;
    for (final t in tabs) {
      if (t.id == activeId) {
        activeTab = t;
        break;
      }
    }
    if (activeTab != null) {
      if (activeTab.type == TerminalTabType.serial) {
        final notifier = ref.read(serialPaneNotifierProvider(activeId).notifier);
        if (notifier.isConnected) {
          return SerialBoardConsole(id: activeId, notifier: notifier);
        }
      } else if (activeTab.type == TerminalTabType.pty) {
        for (final console in ref.read(boardConsoleRegistryProvider).all) {
          if (console.id == activeId && console.isConnected) {
            return console;
          }
        }
      }
    }
  }

  // 2. Fallback to any connected SERIAL pane
  for (final tab in ref.read(terminalTabsNotifierProvider)) {
    if (tab.type != TerminalTabType.serial) continue;
    if (tab.id == activeId) continue; // Already checked
    final notifier = ref.read(serialPaneNotifierProvider(tab.id).notifier);
    if (notifier.isConnected) {
      return SerialBoardConsole(id: tab.id, notifier: notifier);
    }
  }

  // 3. Fallback to any connected PTY pane
  for (final console in ref.read(boardConsoleRegistryProvider).all) {
    if (console.id == activeId) continue; // Already checked
    if (console.kind == ConsoleKind.pty && console.isConnected) {
      return console;
    }
  }
  return null;
}
