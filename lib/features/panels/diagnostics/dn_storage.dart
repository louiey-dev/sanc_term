import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnStoragePanel extends ConsumerWidget {
  const DnStoragePanel({super.key});

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
      panelTitle: 'Storage Check',
      panelSubtitle: 'Flash, disk and filesystem diagnostics',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.storage,
          title: 'Block Devices',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'lsblk', 'lsblk -f'),
              btn(Icons.pie_chart_outline, 'Disk usage', 'df -h'),
              btn(Icons.list_alt, 'Mounts', 'cat /proc/mounts'),
              btn(Icons.memory, 'Partitions', 'cat /proc/partitions'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.health_and_safety,
          title: 'Health & I/O',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.monitor_heart, 'I/O stats', 'cat /proc/diskstats'),
              btn(Icons.warning_amber, 'FS errors',
                  'dmesg | grep -iE "ext4|mmc|nvme|i/o error" | tail -n 20'),
            ],
          ),
        ),
      ],
    );
  }
}
