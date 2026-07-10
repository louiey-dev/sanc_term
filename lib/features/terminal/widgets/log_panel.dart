import 'dart:async';
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
import 'package:sanc_term/features/terminal/providers/terminal_credentials_provider.dart';
import 'package:sanc_term/features/panels/bluetooth/providers/ble_notifier.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/services/ble_service.dart';
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

  /// BLE notification feeds, one per `ble`-type tab (keyed by tab id).
  final Map<String, StreamSubscription<({String characteristicId, Uint8List value})>>
      _bleSubs = {};

  @override
  void initState() {
    super.initState();
    final tabs = ref.read(terminalTabsNotifierProvider);
    _splitController = MultiSplitViewController(
      areas: [for (final t in tabs) Area(id: t.id, flex: 1)],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePtys(tabs);
      _ensureBleFeeds(tabs);
    });
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
    for (final sub in _bleSubs.values) {
      sub.cancel();
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
    // Kill PTYs / BLE feeds belonging to closed tabs.
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
        _bleSubs.remove(id)?.cancel();
      }
    }
    _syncAreas(next);
    _ensurePtys(next);
    _ensureBleFeeds(next);
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
            if (!ref.read(terminalPausedProvider)) {
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

  /// Attach a BLE notification feed to any `ble`-type tab that lacks one.
  void _ensureBleFeeds(List<TerminalTab> tabs) {
    for (final tab in tabs) {
      if (tab.type == TerminalTabType.ble && !_bleSubs.containsKey(tab.id)) {
        _startBleFeed(tab);
      }
    }
  }

  /// Streams every subscribed characteristic's notifications into [tab]'s
  /// terminal (one line per packet) and, when logging is on, into the shared
  /// file logger — so timestamp and save-to-file behave exactly like other panes.
  void _startBleFeed(TerminalTab tab) {
    // Seed the pane with the current session state so it isn't silent when
    // opened mid-connection.
    final st = ref.read(bleNotifierProvider);
    if (st.isConnected) {
      final mtu = st.mtu == null ? '' : ' · MTU ${st.mtu} (payload ${st.mtu! - 3})';
      tab.terminal.write('--- connected$mtu ---\r\n');
      for (final c in st.subscribed) {
        tab.terminal.write('--- subscribed ${_bleSourceLabel(c)} ---\r\n');
      }
    } else {
      tab.terminal.write(
        'Waiting for BLE notifications… connect and subscribe to a '
        'characteristic in a Bluetooth panel.\r\n',
      );
    }
    final ble = ref.read(bleServiceProvider);
    _bleSubs[tab.id] = ble.characteristicUpdates.listen((e) {
      if (ref.read(terminalPausedProvider)) return;
      final label = '[${_bleSourceLabel(e.characteristicId)}] ';
      // Normalize newlines, then tag every line with its source so packets from
      // different characteristics stay recognizable when interleaved.
      final raw =
          utf8.decode(e.value, allowMalformed: true).replaceAll('\r\n', '\n');
      final body = raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;
      final text = '${body.split('\n').map((l) => '$label$l').join('\n')}\n';
      tab.terminal.write(text.replaceAll('\n', '\r\n'));
      ref.read(fileLoggerNotifierProvider.notifier).log(text);
    });
  }

  /// `service/characteristic` short-uuid tag for a value update, resolved from
  /// the connected device's GATT tree (falls back to the characteristic alone
  /// if it isn't found, e.g. before discovery completes).
  String _bleSourceLabel(String charId) {
    for (final s in ref.read(bleNotifierProvider).services) {
      for (final ch in s.characteristics) {
        if (ch.uuid == charId) {
          return '${_shortUuid(s.uuid)}/${_shortUuid(ch.uuid)}';
        }
      }
    }
    return _shortUuid(charId);
  }

  static String _shortUuid(String uuid) {
    final u = uuid.toLowerCase();
    const base = '-0000-1000-8000-00805f9b34fb';
    if (u.startsWith('0000') && u.endsWith(base)) {
      return '0x${u.substring(4, 8).toUpperCase()}';
    }
    return u.split('-').first;
  }

  /// Emits app-side status lines (connect/disconnect, MTU, subscribe changes)
  /// into the BLE DATA panes so the pane gives live feedback even before any
  /// notification arrives. These are app events — not the device's console log.
  void _onBleStateChanged(BleState? prev, BleState next) {
    // Connection transitions.
    if (next.connectedId != null && next.connectedId != prev?.connectedId) {
      _bleStatus('connected');
    } else if (next.connectedId == null && prev?.connectedId != null) {
      _bleStatus('disconnected');
    }
    // MTU negotiated / changed.
    if (next.mtu != null && next.mtu != prev?.mtu) {
      _bleStatus('MTU ${next.mtu} (payload ${next.mtu! - 3})');
    }
    // Subscription changes — but skip the bulk clear that a disconnect causes.
    if (next.connectedId != null) {
      final prevSubs = prev?.subscribed ?? const <String>{};
      for (final c in next.subscribed.difference(prevSubs)) {
        _bleStatus('subscribed ${_bleSourceLabel(c)}');
      }
      for (final c in prevSubs.difference(next.subscribed)) {
        _bleStatus('unsubscribed ${_bleSourceLabel(c)}');
      }
    }
  }

  void _bleStatus(String msg) {
    final bleTabs = ref
        .read(terminalTabsNotifierProvider)
        .where((t) => t.type == TerminalTabType.ble)
        .toList();
    if (bleTabs.isEmpty) return;
    for (final tab in bleTabs) {
      tab.terminal.write('--- $msg ---\r\n');
    }
    ref.read(fileLoggerNotifierProvider.notifier).log('--- $msg ---\n');
  }

  String get _shell => Platform.isWindows
      ? 'cmd.exe'
      : (Platform.environment['SHELL'] ?? 'bash');

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
    ref.listen<BleState>(bleNotifierProvider, _onBleStateChanged);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          _Toolbar(
            isPaused: ref.watch(terminalPausedProvider),
            onPause: () {
              final notifier = ref.read(terminalPausedProvider.notifier);
              notifier.state = !notifier.state;
            },
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
                        ref.read(serialActiveTabIdProvider.notifier).state =
                            tab.id;
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
    final icon = switch (tab.type) {
      TerminalTabType.serial => Icons.usb_outlined,
      TerminalTabType.pty => Icons.terminal,
      TerminalTabType.ble => Icons.bluetooth,
    };

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
                Flexible(
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: labelColor,
                    ),
                  ),
                ),
                if (port.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      port,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    onSelected: (val) => switch (val) {
                      'serial' => tabsNotifier.addSerial(),
                      'ble' => tabsNotifier.addBle(),
                      _ => tabsNotifier.addPty(),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'serial',
                        child: Row(
                          children: [
                            Icon(Icons.usb, size: 14, color: c.muted),
                            const SizedBox(width: 8),
                            Text(
                              'New Serial',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pty',
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: c.muted),
                            const SizedBox(width: 8),
                            Text(
                              'New PTY',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ble',
                        child: Row(
                          children: [
                            Icon(Icons.bluetooth, size: 14, color: c.muted),
                            const SizedBox(width: 8),
                            Text(
                              'New Characteristic Data',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _CredentialsFields(),
          const SizedBox(width: 8),
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

class _CredentialsFields extends ConsumerStatefulWidget {
  const _CredentialsFields();

  @override
  ConsumerState<_CredentialsFields> createState() => _CredentialsFieldsState();
}

class _CredentialsFieldsState extends ConsumerState<_CredentialsFields> {
  late final TextEditingController _ipController;
  late final TextEditingController _idController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(terminalCredentialsNotifierProvider);
    _ipController = TextEditingController(text: initial.ip);
    _idController = TextEditingController(text: initial.id);
    _passwordController = TextEditingController(text: initial.password);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.listen<TerminalCredentials>(terminalCredentialsNotifierProvider, (
      prev,
      next,
    ) {
      if (next.ip != _ipController.text) {
        _ipController.text = next.ip;
      }
      if (next.id != _idController.text) {
        _idController.text = next.id;
      }
      if (next.password != _passwordController.text) {
        _passwordController.text = next.password;
      }
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: c.surface,
              foregroundColor: c.primary,
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () {
              final ip = _ipController.text.trim();
              final id = _idController.text.trim();
              if (ip.isEmpty || id.isEmpty) return;
              sendBoardCommand(ref, context, 'ssh $id@$ip');
            },
            child: const Text('SSH'),
          ),
        ),
        const SizedBox(width: 6),
        _buildField(
          controller: _ipController,
          hintText: 'IP Address',
          width: 120,
          onChanged: (val) => ref
              .read(terminalCredentialsNotifierProvider.notifier)
              .updateIp(val),
        ),
        const SizedBox(width: 6),

        _buildField(
          controller: _idController,
          hintText: 'ID',
          width: 80,
          onChanged: (val) => ref
              .read(terminalCredentialsNotifierProvider.notifier)
              .updateId(val),
        ),
        const SizedBox(width: 6),
        _buildField(
          controller: _passwordController,
          hintText: 'Password',
          width: 100,
          obscureText: true,
          onChanged: (val) => ref
              .read(terminalCredentialsNotifierProvider.notifier)
              .updatePassword(val),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required double width,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
  }) {
    final c = context.colors;
    return SizedBox(
      width: width,
      height: 24,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 11,
          color: c.foreground,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 10,
            color: c.muted.withValues(alpha: 0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          filled: true,
          fillColor: c.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: c.primary),
          ),
        ),
      ),
    );
  }
}
