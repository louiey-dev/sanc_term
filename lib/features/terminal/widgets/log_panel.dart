import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:xterm/xterm.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/core/theme/terminal_theme.dart';
import 'package:sanc_term/features/connection/providers/board_console.dart';
import 'package:sanc_term/features/connection/providers/serial_pane_provider.dart';
import 'package:sanc_term/features/terminal/models/terminal_tab.dart';
import 'package:sanc_term/features/terminal/providers/terminal_instances.dart';
import 'package:sanc_term/services/file_logger_service.dart';

class LogPanel extends ConsumerStatefulWidget {
  const LogPanel({super.key});

  @override
  ConsumerState<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends ConsumerState<LogPanel> {
  late final MultiSplitViewController _splitController;
  final Map<String, Pty> _ptys = {};
  final Map<String, PtyConsole> _consoles = {};
  final Set<String> _ptyStarted = {};
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    final tabs = ref.read(terminalTabsNotifierProvider);
    _splitController = MultiSplitViewController(
      areas: [for (final t in tabs) Area(id: t.id, flex: 1)],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePtys(tabs));
  }

  @override
  void dispose() {
    _splitController.dispose();
    final registry = ref.read(boardConsoleRegistryProvider);
    for (final id in _consoles.keys) {
      registry.unregister(id);
    }
    for (final pty in _ptys.values) {
      pty.kill();
    }
    super.dispose();
  }

  /// Rebuild the split areas to match the current tabs, preserving the flex
  /// (size) of panes that already exist.
  void _syncAreas(List<TerminalTab> tabs) {
    final existing = {for (final a in _splitController.areas) a.id: a};
    _splitController.areas = [
      for (final t in tabs) existing[t.id] ?? Area(id: t.id, flex: 1),
    ];
  }

  /// Start a PTY process for any pty-type tab that hasn't started yet.
  void _ensurePtys(List<TerminalTab> tabs) {
    for (final tab in tabs) {
      if (tab.type == TerminalTabType.pty && !_ptyStarted.contains(tab.id)) {
        _ptyStarted.add(tab.id);
        _startPty(tab);
      }
    }
  }

  void _onTabsChanged(List<TerminalTab>? prev, List<TerminalTab> next) {
    // Kill PTYs belonging to closed tabs.
    if (prev != null) {
      final removed = prev.map((t) => t.id).toSet()
        ..removeAll(next.map((t) => t.id));
      final registry = ref.read(boardConsoleRegistryProvider);
      for (final id in removed) {
        _ptys[id]?.kill();
        _ptys.remove(id);
        _consoles[id]?.markClosed();
        _consoles.remove(id);
        registry.unregister(id);
        _ptyStarted.remove(id);
      }
    }
    _syncAreas(next);
    _ensurePtys(next);
  }

  void _startPty(TerminalTab tab) {
    if (!mounted) return;
    try {
      final pty = Pty.start(
        _shell,
        arguments: _shellArgs,
        columns: tab.terminal.viewWidth,
        rows: tab.terminal.viewHeight,
        environment: {...Platform.environment, 'TERM': 'xterm-256color'},
      );
      _ptys[tab.id] = pty;
      final console = PtyConsole(id: tab.id, pty: pty);
      _consoles[tab.id] = console;
      ref.read(boardConsoleRegistryProvider).register(console);

      pty.output
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
            console.feed(data);
            if (!_isPaused) {
              tab.terminal.write(data);
              ref.read(fileLoggerNotifierProvider.notifier).log(data);
            }
          });
      pty.exitCode.then((code) {
        console.markClosed();
        tab.terminal.write('process exited with code $code\r\n');
      });
      tab.terminal.onOutput = (data) {
        try {
          pty.write(const Utf8Encoder().convert(data));
        } catch (_) {}
      };
      tab.terminal.onResize = (w, h, pw, ph) => pty.resize(h, w);
    } catch (e) {
      tab.terminal.write('Failed to start PTY: $e\r\n');
    }
  }

  String get _shell =>
      Platform.isWindows ? 'cmd.exe' : (Platform.environment['SHELL'] ?? 'bash');

  List<String> get _shellArgs =>
      Platform.isWindows ? ['/k', 'chcp', '65001'] : [];

  TerminalTab? _findTab(List<TerminalTab> tabs, Object? id) {
    for (final t in tabs) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tabs = ref.watch(terminalTabsNotifierProvider);
    final activeTabId = ref.watch(activeTabIdProvider) ?? tabs.firstOrNull?.id;
    ref.listen<List<TerminalTab>>(terminalTabsNotifierProvider, _onTabsChanged);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          _Toolbar(
            isPaused: _isPaused,
            onPause: () => setState(() => _isPaused = !_isPaused),
          ),
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                dividerThickness: 4,
                dividerPainter: DividerPainters.background(
                  color: c.border,
                  highlightedColor: c.primary,
                ),
              ),
              child: MultiSplitView(
                axis: Axis.horizontal,
                controller: _splitController,
                builder: (context, area) {
                  final tab = _findTab(tabs, area.id);
                  if (tab == null) return const SizedBox.shrink();
                  final isSerial = tab.type == TerminalTabType.serial;
                  return _TerminalPane(
                    tab: tab,
                    canClose: tabs.length > 1,
                    isActive: tab.id == activeTabId,
                    onActivate: () {
                      ref.read(activeTabIdProvider.notifier).setActive(tab.id);
                      if (isSerial) {
                        ref.read(serialActiveTabIdProvider.notifier).state = tab.id;
                      }
                      tab.focusNode.requestFocus();
                    },
                    onClose: () => ref
                        .read(terminalTabsNotifierProvider.notifier)
                        .removeTab(tab.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// One terminal in the split view: header (status, label, clear, close) + view.
/// Tapping a SERIAL pane makes it the active pane the connection bar controls.
class _TerminalPane extends ConsumerWidget {
  const _TerminalPane({
    required this.tab,
    required this.canClose,
    required this.isActive,
    required this.onActivate,
    required this.onClose,
  });

  final TerminalTab tab;
  final bool canClose;
  final bool isActive;
  final VoidCallback? onActivate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isSerial = tab.type == TerminalTabType.serial;
    final icon = isSerial ? Icons.usb_outlined : Icons.terminal;

    // Per-pane connection status + port (serial panes only).
    SerialStatus? status;
    String port = '';
    if (isSerial) {
      status = ref.watch(
        serialPaneNotifierProvider(tab.id).select((s) => s.status),
      );
      port = ref.watch(
        serialPaneNotifierProvider(tab.id).select((s) => s.config.port),
      );
    }

    final headerColor = isActive ? c.surface : c.sidebar;
    final labelColor = isActive ? c.primary : c.foreground;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivate?.call(),
      child: Column(
        children: [
          // Pane header
          Container(
            height: 28,
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(
                bottom: BorderSide(
                  color: isActive ? c.primary : c.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (status != null) ...[
                  _StatusDot(status: status),
                  const SizedBox(width: 6),
                ],
                Icon(icon, size: 12, color: c.muted),
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: labelColor,
                  ),
                ),
                if (port.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    port,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ],
                const Spacer(),
                _MiniBtn(
                  icon: Icons.delete_outline,
                  tooltip: 'Clear',
                  color: c.muted,
                  onTap: () {
                    tab.terminal.buffer.clear();
                    tab.terminal.buffer.setCursor(0, 0);
                    tab.controller.clearSelection();
                  },
                ),
                if (canClose)
                  _MiniBtn(
                    icon: Icons.close,
                    tooltip: 'Close',
                    color: c.muted,
                    onTap: onClose,
                  ),
              ],
            ),
          ),
          // Terminal
          Expanded(
            child: TerminalView(
              tab.terminal,
              controller: tab.controller,
              focusNode: tab.focusNode,
              theme: buildTerminalTheme(c, Theme.of(context).brightness),
              backgroundOpacity: 0.0,
              padding: const EdgeInsets.all(8),
              onSecondaryTapDown: (d, o) => _handleRightClick(tab),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRightClick(TerminalTab tab) async {
    final selection = tab.controller.selection;
    if (selection != null) {
      final text = tab.terminal.buffer.getText(selection);
      tab.controller.clearSelection();
      await Clipboard.setData(ClipboardData(text: text));
    } else {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) tab.terminal.paste(data!.text!);
    }
  }
}

// ---------------------------------------------------------------------------

/// Top toolbar: add tab, pause, save to file, timestamp toggle.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.isPaused, required this.onPause});

  final bool isPaused;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final logState = ref.watch(fileLoggerNotifierProvider);
    final logNotifier = ref.read(fileLoggerNotifierProvider.notifier);
    final tabsNotifier = ref.read(terminalTabsNotifierProvider.notifier);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Text(
            'TERMINALS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: c.muted,
            ),
          ),
          const SizedBox(width: 8),
          // Add tab
          PopupMenuButton<String>(
            tooltip: 'Add terminal',
            color: c.card,
            icon: Icon(Icons.add, size: 16, color: c.muted),
            iconSize: 16,
            padding: EdgeInsets.zero,
            onSelected: (val) =>
                val == 'serial' ? tabsNotifier.addSerial() : tabsNotifier.addPty(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'serial',
                child: Row(
                  children: [
                    Icon(Icons.usb, size: 14, color: c.muted),
                    const SizedBox(width: 8),
                    Text('New Serial',
                        style: TextStyle(fontSize: 12, color: c.foreground)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pty',
                child: Row(
                  children: [
                    Icon(Icons.terminal, size: 14, color: c.muted),
                    const SizedBox(width: 8),
                    Text('New PTY',
                        style: TextStyle(fontSize: 12, color: c.foreground)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Pause (global)
          _MiniBtn(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            tooltip: isPaused ? 'Resume' : 'Pause',
            color: isPaused ? c.primary : c.muted,
            onTap: onPause,
          ),
          // Save to file
          _MiniBtn(
            icon: logState.isLogging ? Icons.stop : Icons.save_outlined,
            tooltip: logState.isLogging ? 'Stop logging' : 'Save to file',
            color: logState.isLogging ? c.destructive : c.muted,
            onTap: () async {
              if (logState.isLogging) {
                await logNotifier.stopLogging();
              } else {
                await logNotifier.startLogging();
              }
            },
          ),
          // Timestamp toggle
          _MiniBtn(
            icon: Icons.schedule,
            tooltip: 'Timestamp each line',
            color: logState.timestampEnabled ? c.primary : c.muted,
            onTap: () => logNotifier.setTimestamp(!logState.timestampEnabled),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final SerialStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (status) {
      SerialStatus.connected => c.success,
      SerialStatus.connecting => c.warning,
      SerialStatus.disconnected => c.muted.withValues(alpha: 0.5),
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
