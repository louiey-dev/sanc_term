import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/core/utils/snackbars.dart';
import 'package:sanc_term/features/connection/providers/board_console.dart';
import 'package:sanc_term/features/connection/providers/board_console_selector.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/features/panels/nvidia/tegra_plot.dart';
import 'package:sanc_term/features/panels/nvidia/tegra_stats.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Sample NVIDIA settings panel.
///
/// Layout the other NVIDIA panels can copy:
///  - header with [NvCommonActions] shared across NVIDIA panels (top-right);
///  - a main "overview" block describing what the panel does;
///  - an info block (board identity + reboot / DTB-deploy actions);
///  - a live tegrastats monitor block.
class NvSettingsPanel extends StatelessWidget {
  const NvSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyPanel(
      icon: Icons.settings_applications,
      panelTitle: 'nVidia Settings',
      panelSubtitle: 'Jetson / Tegra board configuration',
      // Common block (top-right) shared by every NVIDIA panel.
      panelActions: [NvCommonActions()],
      children: [_OverviewBlock(), _InfoBlock(), _TegraStatsBlock()],
    );
  }
}

// ---------------------------------------------------------------------------
// Main block — explains what this panel does.

class _OverviewBlock extends StatelessWidget {
  const _OverviewBlock();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanelBody(
      icon: Icons.info_outline,
      title: 'About this panel',
      child: Text(
        'Configure NVIDIA Jetson / Tegra targets: review the board identity, '
        'reboot the device, deploy an updated device-tree blob (DTB), and watch '
        'live tegrastats (CPU, GPU, RAM and temperature).',
        style: TextStyle(fontSize: 12, height: 1.5, color: c.foreground),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub block — board info + lifecycle buttons (reboot / DTB deploy).

class _InfoBlock extends ConsumerStatefulWidget {
  const _InfoBlock();

  @override
  ConsumerState<_InfoBlock> createState() => _InfoBlockState();
}

class _InfoBlockState extends ConsumerState<_InfoBlock> {
  static const _empty = '—';

  String _model = _empty;
  String _l4t = _empty;
  String _ip = _empty;
  String _uptime = _empty;

  bool _loading = false;
  String? _status;
  bool _isWarning = false;

  String _sourceLabel(ConsoleKind kind) =>
      kind == ConsoleKind.pty ? 'PTY / SSH' : 'serial';

  /// Reads board identity from the highest-priority connected console.
  Future<void> _readInfo() async {
    final console = pickBoardConsole(ref);
    if (console == null) {
      setState(() {
        _isWarning = true;
        _status = 'No connected PTY/SSH or serial pane — connect one first.';
      });
      showErrorSnackbar(context, 'No connected console to read from');
      return;
    }

    setState(() {
      _loading = true;
      _isWarning = false;
      _status = 'Reading via ${_sourceLabel(console.kind)}…';
    });

    try {
      final model = _clean(await console.run('cat /proc/device-tree/model'));
      final l4t = _parseL4t(await console.run('cat /etc/nv_tegra_release'));
      final ip = _firstToken(await console.run('hostname -I'));
      final uptime = _parseUptime(await console.run('uptime -p'));
      if (!mounted) return;
      setState(() {
        _model = model.isEmpty ? _empty : model;
        _l4t = l4t.isEmpty ? _empty : l4t;
        _ip = ip.isEmpty ? _empty : ip;
        _uptime = uptime.isEmpty ? _empty : uptime;
        _status = 'Source: ${_sourceLabel(console.kind)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWarning = true;
        _status = 'Read failed: $e';
      });
      showErrorSnackbar(context, 'Board info read failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- output parsing ---

  String _clean(String s) =>
      s.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();

  String _firstToken(String s) {
    final parts = _clean(s).split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// `# R36 (release), REVISION: 3.0, ...` -> `36.3`.
  String _parseL4t(String s) {
    final major = RegExp(r'R(\d+)').firstMatch(s)?.group(1);
    final rev = RegExp(r'REVISION:\s*([\d.]+)').firstMatch(s)?.group(1);
    if (major != null && rev != null) return '$major.$rev';
    final first = _clean(s).split('\n').first;
    return first;
  }

  /// `up 12 hours, 4 minutes` -> `12 hours, 4 minutes`.
  String _parseUptime(String s) {
    final t = _clean(s);
    return t.startsWith('up ') ? t.substring(3) : t;
  }

  Future<void> _confirmReboot() async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: c.border),
        ),
        title: Text('Reboot board?', style: TextStyle(color: c.foreground)),
        content: Text(
          'The target will restart and the connection will drop.',
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: c.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reboot', style: TextStyle(color: c.destructive)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      showSnackbar(context, 'Reboot: not implemented');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanelBody(
      icon: Icons.memory,
      title: 'Board Info',
      subtitle: 'Identity and lifecycle actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              InfoTile(label: 'Model', value: _model),
              InfoTile(label: 'L4T', value: _l4t),
              InfoTile(label: 'IP', value: _ip),
              InfoTile(label: 'Uptime', value: _uptime),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              PanelActionButton(
                icon: Icons.restart_alt,
                label: 'Reboot',
                tooltipStr: 'Reboot the target board',
                onPressed: _confirmReboot,
              ),
              const SizedBox(width: 8),
              PanelActionButton(
                icon: Icons.upload_file,
                label: 'DTB Deploy',
                tooltipStr: 'Deploy an updated device-tree blob',
                onPressed: () =>
                    showSnackbar(context, 'DTB deploy: not implemented'),
              ),
              const SizedBox(width: 8),
              PanelActionButton(
                icon: Icons.refresh,
                label: _loading ? 'Reading…' : 'Read Info',
                tooltipStr: 'Read live board info (PTY/SSH, then serial)',
                onPressed: _loading ? null : _readInfo,
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: TextStyle(
                fontSize: 11,
                color: _isWarning ? c.warning : c.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub block — live tegrastats monitor (simulated sample data).

class _TegraStatsBlock extends ConsumerStatefulWidget {
  const _TegraStatsBlock();

  @override
  ConsumerState<_TegraStatsBlock> createState() => _TegraStatsBlockState();
}

class _TegraStatsBlockState extends ConsumerState<_TegraStatsBlock> {
  // One short tegrastats sample: start it, let one line print, then stop.
  static const _sampleCmd =
      'tegrastats --interval 1000 & sleep 1.5; kill \$! 2>/dev/null';

  // ≈1 hour of samples at the 2s auto-refresh interval (1800 ticks).
  static const _maxHistory = 1800;

  Timer? _timer;
  bool _loading = false;
  TegraStatsData? _data;
  String? _status;
  bool _isWarning = false;

  /// Rolling history for the live plot; the plot window listens to this.
  final ValueNotifier<List<TegraSample>> _history = ValueNotifier([]);

  /// The floating plot window while open (null when closed).
  OverlayEntry? _plotEntry;

  bool get _running => _timer != null;

  void _toggle() {
    if (_running) {
      _stop();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _sample());
      _sample();
      setState(() {});
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  /// Reads one tegrastats sample over the selected console and parses it.
  Future<void> _sample() async {
    if (_loading) return;
    final console = pickBoardConsole(ref);
    if (console == null) {
      _stop();
      setState(() {
        _isWarning = true;
        _status = 'No connected serial or PTY/SSH pane — connect one first.';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final out = await console.run(
        _sampleCmd,
        timeout: const Duration(seconds: 6),
      );
      final data = parseTegraStatsBlock(out);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (data != null) {
          _data = data;
          _isWarning = false;
          _status =
              'Source: ${console.kind == ConsoleKind.pty ? 'PTY / SSH' : 'serial'}';
          _appendHistory(data);
        } else {
          _isWarning = true;
          _status = 'No tegrastats output — is it installed / on PATH?';
        }
      });
    } catch (e) {
      if (!mounted) return;
      _stop();
      setState(() {
        _loading = false;
        _isWarning = true;
        _status = 'Read failed: $e';
      });
    }
  }

  void _appendHistory(TegraStatsData data) {
    final list = [..._history.value, tegraSample(data)];
    if (list.length > _maxHistory) {
      list.removeRange(0, list.length - _maxHistory);
    }
    _history.value = list;
  }

  /// Opens the live plot as a draggable/resizable floating window inside the app.
  void _plot() {
    if (_plotEntry != null) return; // already open
    _history.value = <TegraSample>[]; // start each plot from current data
    final entry = OverlayEntry(
      builder: (_) => TegraPlotWindow(history: _history, onClose: _closePlot),
    );
    _plotEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _closePlot() {
    _plotEntry?.remove();
    _plotEntry = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _plotEntry?.remove();
    _plotEntry = null;
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanelBody(
      icon: Icons.monitor_heart_outlined,
      title: 'Tegra Stats',
      subtitle: _running
          ? 'Auto · 2s'
          : (_loading ? 'Reading…' : 'Stopped'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelActionButton(
            icon: Icons.refresh,
            label: 'Read',
            tooltipStr: 'Read one tegrastats sample',
            onPressed: _loading ? null : _sample,
          ),
          const SizedBox(width: 8),
          PanelActionButton(
            icon: _running ? Icons.stop : Icons.play_arrow,
            label: _running ? 'Stop' : 'Auto',
            tooltipStr: _running ? 'Stop auto-refresh' : 'Auto-refresh (2s)',
            onPressed: _toggle,
          ),
          const SizedBox(width: 8),
          PanelActionButton(
            icon: Icons.show_chart,
            label: 'Plot',
            tooltipStr: 'Open live plot window',
            onPressed: _plot,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_data != null)
            buildStatsDisplay(c, _data!)
          else
            Text(
              _loading ? 'Reading tegrastats…' : 'No data yet — press Read.',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: TextStyle(
                fontSize: 11,
                color: _isWarning ? c.warning : c.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

