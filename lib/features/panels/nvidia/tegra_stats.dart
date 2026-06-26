import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/shared/widgets/common.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class TegraStatsCpuCore {
  final int usagePct; // -1 means core is offline
  final int freqMhz;
  const TegraStatsCpuCore(this.usagePct, this.freqMhz);
  bool get isOff => usagePct < 0;
}

class TegraStatsData {
  final int ramUsed, ramTotal;
  final int swapUsed, swapTotal;
  final List<TegraStatsCpuCore> cpus;
  final int gpuLoadPct;
  final String gpuFreq;
  final String emcFreq;
  final Map<String, String> temps;
  final Map<String, String> power;

  const TegraStatsData({
    required this.ramUsed,
    required this.ramTotal,
    required this.swapUsed,
    required this.swapTotal,
    required this.cpus,
    required this.gpuLoadPct,
    required this.gpuFreq,
    required this.emcFreq,
    required this.temps,
    required this.power,
  });
}

/// One point in time, reduced to the four metrics the live plot graphs.
class TegraSample {
  final double cpuTemp;
  final double gpuTemp;
  final double gpuLoad;
  final double memLoad;

  const TegraSample({
    required this.cpuTemp,
    required this.gpuTemp,
    required this.gpuLoad,
    required this.memLoad,
  });

  Map<String, double> toMap() => {
        'cpuTemp': cpuTemp,
        'gpuTemp': gpuTemp,
        'gpuLoad': gpuLoad,
        'memLoad': memLoad,
      };

  factory TegraSample.fromMap(Map<dynamic, dynamic> m) => TegraSample(
        cpuTemp: (m['cpuTemp'] as num?)?.toDouble() ?? 0,
        gpuTemp: (m['gpuTemp'] as num?)?.toDouble() ?? 0,
        gpuLoad: (m['gpuLoad'] as num?)?.toDouble() ?? 0,
        memLoad: (m['memLoad'] as num?)?.toDouble() ?? 0,
      );
}

double _tempValue(Map<String, String> temps, String needle) {
  for (final e in temps.entries) {
    if (e.key.toLowerCase().contains(needle)) {
      return double.tryParse(e.value.replaceAll('°C', '')) ?? 0;
    }
  }
  return 0;
}

/// Reduces a full stats line to the plotted metrics.
TegraSample tegraSample(TegraStatsData s) => TegraSample(
      cpuTemp: _tempValue(s.temps, 'cpu'),
      gpuTemp: _tempValue(s.temps, 'gpu'),
      gpuLoad: s.gpuLoadPct.toDouble(),
      memLoad: s.ramTotal > 0 ? s.ramUsed / s.ramTotal * 100 : 0,
    );

// ---------------------------------------------------------------------------
// Parser — one `tegrastats` line, e.g.
// RAM 4096/30622MB ... CPU [12%@1497,...] GR3D_FREQ 0%@305 ... cpu@45C ...
// ---------------------------------------------------------------------------

TegraStatsData? parseTegraStats(String line) {
  if (!line.contains('RAM ') || !line.contains('CPU [')) return null;

  final ramM = RegExp(r'RAM (\d+)/(\d+)MB').firstMatch(line);
  if (ramM == null) return null;
  final ramUsed = int.tryParse(ramM.group(1)!) ?? 0;
  final ramTotal = int.tryParse(ramM.group(2)!) ?? 0;

  int swapUsed = 0, swapTotal = 0;
  final swapM = RegExp(r'SWAP (\d+)/(\d+)MB').firstMatch(line);
  if (swapM != null) {
    swapUsed = int.tryParse(swapM.group(1)!) ?? 0;
    swapTotal = int.tryParse(swapM.group(2)!) ?? 0;
  }

  final List<TegraStatsCpuCore> cpus = [];
  final cpuM = RegExp(r'CPU \[([^\]]+)\]').firstMatch(line);
  if (cpuM != null) {
    for (final part in cpuM.group(1)!.split(',')) {
      final m = RegExp(r'(\d+)%@(\d+)').firstMatch(part);
      if (m != null) {
        cpus.add(
          TegraStatsCpuCore(int.parse(m.group(1)!), int.parse(m.group(2)!)),
        );
      } else {
        cpus.add(const TegraStatsCpuCore(-1, 0));
      }
    }
  }

  String gpuFreq = '', emcFreq = '';
  int gpuLoadPct = 0;
  final gr3dM = RegExp(r'GR3D_FREQ (\d+)%@(\d+)').firstMatch(line);
  if (gr3dM != null) {
    gpuLoadPct = int.tryParse(gr3dM.group(1)!) ?? 0;
    gpuFreq = '${gr3dM.group(2)!} MHz';
  }

  final emcM = RegExp(r'EMC_FREQ \d+%@(\d+)').firstMatch(line);
  if (emcM != null) emcFreq = '${emcM.group(1)!} MHz';

  final Map<String, String> temps = {};
  for (final m in RegExp(r'(\w+)@(\d+(?:\.\d+)?)C').allMatches(line)) {
    temps[m.group(1)!] = '${m.group(2)!}°C';
  }

  final Map<String, String> power = {};
  // Older boards: "VDD_IN@1560mW"
  for (final m in RegExp(r'(\w+)@(\d+(?:\.\d+)?)mW').allMatches(line)) {
    power[m.group(1)!] = '${m.group(2)!} mW';
  }
  // Orin boards: "VDD_GPU_SOC 3568mW/3701mW" (current/average pair)
  for (final m
      in RegExp(r'(\w+)\s+(\d+(?:\.\d+)?)mW/\d+(?:\.\d+)?mW').allMatches(line)) {
    power[m.group(1)!] = '${m.group(2)!} mW';
  }

  return TegraStatsData(
    ramUsed: ramUsed,
    ramTotal: ramTotal,
    swapUsed: swapUsed,
    swapTotal: swapTotal,
    cpus: cpus,
    gpuLoadPct: gpuLoadPct,
    gpuFreq: gpuFreq,
    emcFreq: emcFreq,
    temps: temps,
    power: power,
  );
}

/// Returns the most recent parseable stats line from a multi-line capture,
/// or null if none parse.
TegraStatsData? parseTegraStatsBlock(String text) {
  TegraStatsData? last;
  for (final line in text.split('\n')) {
    final parsed = parseTegraStats(line);
    if (parsed != null) last = parsed;
  }
  return last;
}

// ---------------------------------------------------------------------------
// Color helpers (now take the active palette instead of static AppColors)
// ---------------------------------------------------------------------------

Color tegraUsageColor(AppColors c, int pct) {
  if (pct < 50) return c.success;
  if (pct < 80) return c.warning;
  return c.destructive;
}

Color tegraTemperatureColor(AppColors c, String val) {
  final t = double.tryParse(val.replaceAll('°C', '')) ?? 0;
  if (t < 50) return c.success;
  if (t < 70) return c.warning;
  return c.destructive;
}

// ---------------------------------------------------------------------------
// Public display widget
// ---------------------------------------------------------------------------

Widget buildStatsDisplay(AppColors c, TegraStatsData s) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel(c, 'MEMORY'),
      const SizedBox(height: 4),
      _memTable(c, s),
      if (s.cpus.isNotEmpty) ...[
        const SizedBox(height: 10),
        _sectionLabel(c, 'CPU CORES'),
        const SizedBox(height: 4),
        _cpuTable(c, s.cpus),
      ],
      if (s.gpuFreq.isNotEmpty || s.emcFreq.isNotEmpty) ...[
        const SizedBox(height: 10),
        _sectionLabel(c, 'FREQUENCY'),
        const SizedBox(height: 4),
        _freqTable(c, s),
      ],
      if (s.temps.isNotEmpty) ...[
        const SizedBox(height: 10),
        _sectionLabel(c, 'TEMPERATURES'),
        const SizedBox(height: 4),
        _tempsTable(c, s.temps),
      ],
      if (s.power.isNotEmpty) ...[
        const SizedBox(height: 10),
        _sectionLabel(c, 'POWER'),
        const SizedBox(height: 4),
        _powerTable(c, s.power),
      ],
    ],
  );
}

// ---------------------------------------------------------------------------
// Private table helpers
// ---------------------------------------------------------------------------

Widget _sectionLabel(AppColors c, String text) => Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: c.muted,
        letterSpacing: 1.2,
      ),
    );

Widget _tc(
  AppColors c,
  String text, {
  Color? color,
  TextAlign align = TextAlign.left,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 11,
        fontFamily: 'Consolas',
        color: color ?? c.foreground,
      ),
    ),
  );
}

Widget _th(AppColors c, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontFamily: 'Consolas',
        fontWeight: FontWeight.w700,
        color: c.muted,
        letterSpacing: 0.8,
      ),
    ),
  );
}

TableBorder _border(AppColors c) => TableBorder.all(
      color: c.border,
      width: 0.5,
      borderRadius: BorderRadius.circular(4),
    );

Widget _memTable(AppColors c, TegraStatsData s) {
  return Table(
    columnWidths: const {
      0: FixedColumnWidth(44),
      1: FlexColumnWidth(),
      2: FixedColumnWidth(120),
      3: FixedColumnWidth(36),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    border: _border(c),
    children: [
      _memRow(c, 'RAM', s.ramUsed, s.ramTotal, isOdd: false),
      _memRow(c, 'SWAP', s.swapUsed, s.swapTotal, isOdd: true),
    ],
  );
}

TableRow _memRow(
  AppColors c,
  String label,
  int used,
  int total, {
  required bool isOdd,
}) {
  final pct = total > 0 ? used / total : 0.0;
  final pctInt = (pct * 100).toInt();
  final color = tegraUsageColor(c, pctInt);
  return TableRow(
    decoration: BoxDecoration(
      color: isOdd ? c.surface.withValues(alpha: 0.4) : null,
    ),
    children: [
      _tc(c, label, color: c.muted),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: ProgressBar(value: pct, color: color, height: 6),
      ),
      _tc(c, '$used / $total MB'),
      _tc(c, '$pctInt%', color: color, align: TextAlign.right),
    ],
  );
}

Widget _cpuTable(AppColors c, List<TegraStatsCpuCore> cpus) {
  return Table(
    columnWidths: const {
      0: FixedColumnWidth(36),
      1: FixedColumnWidth(44),
      2: FlexColumnWidth(),
      3: FixedColumnWidth(80),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    border: _border(c),
    children: [
      TableRow(
        decoration: BoxDecoration(color: c.surface),
        children: [_th(c, 'Core'), _th(c, 'Usage'), _th(c, ''), _th(c, 'Freq')],
      ),
      for (int i = 0; i < cpus.length; i++)
        _cpuRow(c, i, cpus[i], isOdd: i.isOdd),
    ],
  );
}

TableRow _cpuRow(
  AppColors c,
  int index,
  TegraStatsCpuCore core, {
  required bool isOdd,
}) {
  final bg = isOdd
      ? BoxDecoration(color: c.surface.withValues(alpha: 0.4))
      : null;
  if (core.isOff) {
    return TableRow(
      decoration: bg,
      children: [
        _tc(c, 'C$index', color: c.muted),
        _tc(c, 'OFF', color: c.muted),
        const SizedBox(),
        _tc(c, '—', color: c.muted),
      ],
    );
  }
  final color = tegraUsageColor(c, core.usagePct);
  return TableRow(
    decoration: bg,
    children: [
      _tc(c, 'C$index', color: c.muted),
      _tc(c, '${core.usagePct}%', color: color),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: ProgressBar(value: core.usagePct / 100, color: color, height: 5),
      ),
      _tc(c, '${core.freqMhz} MHz'),
    ],
  );
}

Widget _freqTable(AppColors c, TegraStatsData s) {
  return Table(
    columnWidths: const {0: FixedColumnWidth(60), 1: FlexColumnWidth()},
    border: _border(c),
    children: [
      if (s.gpuFreq.isNotEmpty)
        TableRow(
          children: [
            _tc(c, 'GR3D', color: c.muted),
            _tc(c, s.gpuFreq, color: c.chartBlue),
          ],
        ),
      if (s.emcFreq.isNotEmpty)
        TableRow(
          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.4)),
          children: [
            _tc(c, 'EMC', color: c.muted),
            _tc(c, s.emcFreq),
          ],
        ),
    ],
  );
}

Widget _tempsTable(AppColors c, Map<String, String> temps) {
  final entries = temps.entries.toList();
  final rows = <TableRow>[];
  for (int i = 0; i < entries.length; i += 3) {
    final chunk = entries.sublist(i, (i + 3).clamp(0, entries.length));
    final isOdd = (i ~/ 3).isOdd;
    rows.add(
      TableRow(
        decoration: isOdd
            ? BoxDecoration(color: c.surface.withValues(alpha: 0.4))
            : null,
        children: [
          for (final e in chunk) ...[
            _tc(c, e.key, color: c.muted),
            _tc(c, e.value, color: tegraTemperatureColor(c, e.value)),
          ],
          for (int p = chunk.length; p < 3; p++) ...[
            const SizedBox(),
            const SizedBox(),
          ],
        ],
      ),
    );
  }
  return Table(
    columnWidths: const {
      0: FixedColumnWidth(52),
      1: FixedColumnWidth(52),
      2: FixedColumnWidth(52),
      3: FixedColumnWidth(52),
      4: FixedColumnWidth(52),
      5: FlexColumnWidth(),
    },
    border: _border(c),
    children: rows,
  );
}

Widget _powerTable(AppColors c, Map<String, String> power) {
  final entries = power.entries.toList();
  final totalMw = entries.fold<int>(
    0,
    (sum, e) => sum + (int.tryParse(e.value.replaceAll(' mW', '')) ?? 0),
  );
  return Table(
    columnWidths: const {0: FlexColumnWidth(), 1: FixedColumnWidth(88)},
    border: _border(c),
    children: [
      for (int i = 0; i < entries.length; i++)
        TableRow(
          decoration: i.isOdd
              ? BoxDecoration(color: c.surface.withValues(alpha: 0.4))
              : null,
          children: [
            _tc(c, entries[i].key, color: c.muted),
            _tc(c, entries[i].value, color: c.chartBlue, align: TextAlign.right),
          ],
        ),
      TableRow(
        decoration: BoxDecoration(color: c.surface),
        children: [
          _tc(c, 'TOTAL', color: c.foreground),
          _tc(c, '$totalMw mW', color: c.primary, align: TextAlign.right),
        ],
      ),
    ],
  );
}
