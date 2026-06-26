import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnCpuPanel extends ConsumerWidget {
  const DnCpuPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PanelActionButton btn(IconData i, String label, String cmd) =>
        PanelActionButton(
          icon: i,
          label: label,
          tooltipStr: cmd,
          onPressed: () => sendBoardCommand(ref, context, cmd),
        );
    return MyPanel(
      icon: Icons.memory,
      panelTitle: 'CPU Check',
      panelSubtitle: 'Processor topology, frequency and load',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.developer_board,
          title: 'Topology',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'lscpu', 'lscpu'),
              btn(Icons.info, 'cpuinfo', 'cat /proc/cpuinfo'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.speed,
          title: 'Frequency & Load',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.speed, 'Cur Freq',
                  'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null'),
              btn(Icons.tune, 'Governor',
                  'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null'),
              btn(Icons.show_chart, 'Load Avg', 'cat /proc/loadavg'),
              btn(Icons.monitor_heart, 'Top', 'top -bn1 | head -n 15'),
            ],
          ),
        ),
      ],
    );
  }
}
