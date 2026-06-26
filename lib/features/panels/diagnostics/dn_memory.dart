import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnMemoryPanel extends ConsumerWidget {
  const DnMemoryPanel({super.key});

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
      icon: Icons.sd_storage,
      panelTitle: 'Memory Check',
      panelSubtitle: 'RAM, swap and cache usage',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.memory,
          title: 'Usage',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.pie_chart, 'free -h', 'free -h'),
              btn(Icons.info, 'meminfo', 'cat /proc/meminfo'),
              btn(Icons.swap_horiz, 'Swaps', 'cat /proc/swaps'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.analytics,
          title: 'Statistics',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.show_chart, 'vmstat', 'vmstat 1 3'),
              btn(Icons.layers, 'Slabtop', 'slabtop -o | head -n 20'),
            ],
          ),
        ),
      ],
    );
  }
}
