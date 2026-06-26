import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcStoragePanel extends ConsumerWidget {
  const RcStoragePanel({super.key});

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
      icon: Icons.storage,
      panelTitle: 'Rockchip Storage',
      panelSubtitle: 'eMMC / SD / partitions',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.storage,
          title: 'Block Devices',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.storage, 'lsblk', 'lsblk -f'),
              btn(Icons.pie_chart_outline, 'Disk usage', 'df -h'),
              btn(Icons.list, 'Mounts', 'cat /proc/mounts'),
              btn(Icons.memory, 'Partitions', 'cat /proc/partitions'),
            ],
          ),
        ),
      ],
    );
  }
}
