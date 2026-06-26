import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/nvidia/tegra_stats.dart';

/// The plot body: a small point counter + the two live charts. Reused by
/// [TegraPlotWindow]; rebuilds whenever a new sample is added.
class TegraPlotContent extends StatelessWidget {
  const TegraPlotContent({super.key, required this.history});

  final ValueListenable<List<TegraSample>> history;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<List<TegraSample>>(
      valueListenable: history,
      builder: (context, samples, _) {
        final mins = (samples.length * 2 / 60).toStringAsFixed(0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${samples.length} pts · ~$mins min',
              style: TextStyle(fontSize: 10, color: c.muted),
            ),
            const SizedBox(height: 8),
            _ChartSection(
              title: 'THERMAL',
              unit: '°C',
              series: [
                _Series('CPU', c.chartBlue, [for (final s in samples) s.cpuTemp]),
                _Series('GPU', c.destructive, [
                  for (final s in samples) s.gpuTemp,
                ]),
              ],
            ),
            const SizedBox(height: 18),
            _ChartSection(
              title: 'LOAD',
              unit: '%',
              series: [
                _Series('GPU', c.primary, [for (final s in samples) s.gpuLoad]),
                _Series('MEM', c.warning, [for (final s in samples) s.memLoad]),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A draggable, resizable floating window (mounted in the app [Overlay]) that
/// hosts the live plot. Drag the title bar to move; drag the bottom-right grip
/// to resize. Stays within the app window.
class TegraPlotWindow extends StatefulWidget {
  const TegraPlotWindow({
    super.key,
    required this.history,
    required this.onClose,
  });

  final ValueListenable<List<TegraSample>> history;
  final VoidCallback onClose;

  @override
  State<TegraPlotWindow> createState() => _TegraPlotWindowState();
}

class _TegraPlotWindowState extends State<TegraPlotWindow> {
  static const _minW = 360.0, _minH = 300.0, _maxW = 1400.0, _maxH = 1000.0;

  Offset _pos = const Offset(120, 80);
  Size _size = const Size(560, 460);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screen = MediaQuery.of(context).size;
    // Keep the title bar reachable on screen.
    final left = _pos.dx.clamp(0.0, math.max(0.0, screen.width - 120)).toDouble();
    final top = _pos.dy.clamp(0.0, math.max(0.0, screen.height - 48)).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _size.width,
          height: _size.height,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _titleBar(c),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: SingleChildScrollView(
                          child: TegraPlotContent(history: widget.history),
                        ),
                      ),
                      Positioned(right: 0, bottom: 0, child: _resizeGrip(c)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBar(AppColors c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => setState(() => _pos = _pos + d.delta),
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: c.sidebar,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Text(
              'Tegra Stats — Live Plot',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.foreground,
              ),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resizeGrip(AppColors c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => setState(() {
        _size = Size(
          (_size.width + d.delta.dx).clamp(_minW, _maxW),
          (_size.height + d.delta.dy).clamp(_minH, _maxH),
        );
      }),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(Icons.open_in_full, size: 12, color: c.muted),
      ),
    );
  }
}

class _Series {
  _Series(this.label, this.color, this.values);
  final String label;
  final Color color;
  final List<double> values;
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.unit,
    required this.series,
  });

  final String title;
  final String unit;
  final List<_Series> series;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: c.muted,
              ),
            ),
            const Spacer(),
            for (final s in series) ...[
              Container(width: 12, height: 3, color: s.color),
              const SizedBox(width: 4),
              Text(s.label, style: TextStyle(fontSize: 10, color: c.muted)),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              series: series,
              unit: unit,
              gridColor: c.border,
              textColor: c.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.unit,
    required this.gridColor,
    required this.textColor,
  });

  final List<_Series> series;
  final String unit;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0, rightPad = 6.0, topPad = 6.0, bottomPad = 4.0;
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );

    // Y range auto-scales to the data (with 10% padding) so it does not start
    // at zero — small load/temperature changes stay visible.
    double lo, hi;
    final all = [for (final s in series) ...s.values];
    if (all.isEmpty) {
      lo = 0;
      hi = 1;
    } else {
      lo = all.reduce(math.min);
      hi = all.reduce(math.max);
      if (lo == hi) {
        lo -= 1;
        hi += 1;
      }
      final pad = (hi - lo) * 0.1;
      lo -= pad;
      hi += pad;
    }

    void label(String s, Offset o) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: textColor,
            fontSize: 9,
            fontFamily: 'Consolas',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o);
    }

    // Horizontal grid + Y labels.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    const rows = 4;
    for (int i = 0; i <= rows; i++) {
      final y = plot.top + plot.height * i / rows;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final val = hi - (hi - lo) * i / rows;
      label('${val.toStringAsFixed(0)}$unit', Offset(2, y - 5));
    }

    // Series polylines.
    for (final s in series) {
      if (s.values.length < 2) continue;
      final path = Path();
      for (int i = 0; i < s.values.length; i++) {
        final x = plot.left + plot.width * (i / (s.values.length - 1));
        final norm = ((s.values[i] - lo) / (hi - lo)).clamp(0.0, 1.0);
        final y = plot.bottom - plot.height * norm;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
