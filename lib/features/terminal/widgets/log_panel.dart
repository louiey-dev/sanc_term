import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/terminal/providers/terminal_instances.dart';
import 'package:sanc_term/services/file_logger_service.dart';

class LogPanel extends ConsumerStatefulWidget {
  const LogPanel({super.key});

  @override
  ConsumerState<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends ConsumerState<LogPanel>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;
  bool _ptyStarted = false;
  late TabController _tabController;
  Pty? _pty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_ptyStarted) {
      _ptyStarted = true;
      _startPty();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pty?.kill();
    super.dispose();
  }

  void _startPty() {
    if (!mounted) return;
    final ptyTerminal = ref.read(ptyTerminalProvider);
    try {
      _pty = Pty.start(
        _shell,
        arguments: _shellArguments,
        columns: ptyTerminal.viewWidth,
        rows: ptyTerminal.viewHeight,
        environment: {...Platform.environment, 'TERM': 'xterm-256color'},
      );
      _pty!.output
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
            if (!_isPaused) {
              ptyTerminal.write(data);
              ref.read(fileLoggerNotifierProvider.notifier).log(data);
            }
          });
      _pty!.exitCode.then(
        (code) => ptyTerminal.write('process exited with code $code\r\n'),
      );
      ptyTerminal.onOutput = (data) {
        try {
          _pty?.write(const Utf8Encoder().convert(data));
        } catch (_) {}
      };
      ptyTerminal.onResize = (w, h, pw, ph) => _pty?.resize(h, w);
    } catch (e) {
      ptyTerminal.write('Failed to start PTY: $e\r\n');
    }
  }

  String get _shell {
    if (Platform.isWindows) return 'cmd.exe';
    return Platform.environment['SHELL'] ?? 'bash';
  }

  List<String> get _shellArguments {
    if (Platform.isWindows) return ['/k', 'chcp', '65001'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final serialTerminal = ref.watch(serialTerminalProvider);
    final ptyTerminal = ref.watch(ptyTerminalProvider);
    final serialController = ref.watch(serialTerminalControllerProvider);
    final ptyController = ref.watch(ptyTerminalControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          _Header(
            tabController: _tabController,
            isPaused: _isPaused,
            onPause: () => setState(() => _isPaused = !_isPaused),
            onClear: () {
              final isSerial = _tabController.index == 0;
              final terminal = isSerial ? serialTerminal : ptyTerminal;
              final controller = isSerial ? serialController : ptyController;
              terminal.buffer.clear();
              terminal.buffer.setCursor(0, 0);
              controller.clearSelection();
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TerminalView(
                  serialTerminal,
                  controller: serialController,
                  backgroundOpacity: 0.0,
                  padding: const EdgeInsets.all(8),
                  onSecondaryTapDown: (d, o) =>
                      _handleRightClick(serialTerminal, serialController),
                ),
                TerminalView(
                  ptyTerminal,
                  controller: ptyController,
                  backgroundOpacity: 0.0,
                  padding: const EdgeInsets.all(8),
                  onSecondaryTapDown: (d, o) =>
                      _handleRightClick(ptyTerminal, ptyController),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRightClick(
    Terminal terminal,
    TerminalController controller,
  ) async {
    final selection = controller.selection;
    if (selection != null) {
      final text = terminal.buffer.getText(selection);
      controller.clearSelection();
      await Clipboard.setData(ClipboardData(text: text));
    } else {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) terminal.paste(data!.text!);
    }
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.tabController,
    required this.isPaused,
    required this.onPause,
    required this.onClear,
  });

  final TabController tabController;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final logState = ref.watch(fileLoggerNotifierProvider);
    final logNotifier = ref.read(fileLoggerNotifierProvider.notifier);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: c.primary,
              labelColor: c.foreground,
              unselectedLabelColor: c.muted,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              tabs: const [Tab(text: 'SERIAL'), Tab(text: 'PTY')],
            ),
          ),
          _IconBtn(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            color: isPaused ? c.primary : c.muted,
            tooltip: isPaused ? 'Resume' : 'Pause',
            onTap: onPause,
          ),
          const SizedBox(width: 4),
          _IconBtn(
            icon: Icons.delete_outline,
            color: c.muted,
            tooltip: 'Clear',
            onTap: onClear,
          ),
          const SizedBox(width: 4),
          _IconBtn(
            icon: logState.isLogging ? Icons.stop : Icons.save_outlined,
            color: logState.isLogging ? c.destructive : c.muted,
            tooltip: logState.isLogging ? 'Stop logging' : 'Save to file',
            onTap: () async {
              if (logState.isLogging) {
                await logNotifier.stopLogging();
              } else {
                await logNotifier.startLogging();
              }
            },
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Timestamp each line',
            child: InkWell(
              onTap: () => logNotifier.setTimestamp(!logState.timestampEnabled),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.schedule,
                  size: 16,
                  color: logState.timestampEnabled ? c.primary : c.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
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
