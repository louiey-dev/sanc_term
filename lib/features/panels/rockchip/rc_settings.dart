import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcSettingsPanel extends ConsumerWidget {
  const RcSettingsPanel({super.key});

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
      icon: Icons.settings_applications,
      panelTitle: 'Rockchip Settings',
      panelSubtitle: 'Rockchip board configuration and base info',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.info_outline,
          title: 'Board Info',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.info, 'Board IP', 'ifconfig -a'),
              btn(Icons.lan, 'ip addr', 'ip addr show'),
              btn(Icons.memory, 'Model', 'cat /proc/device-tree/model'),
              btn(Icons.info_outline, 'Kernel', 'uname -a'),
              btn(Icons.schedule, 'Uptime', 'uptime -p'),
            ],
          ),
        ),
      ],
    );
  }
}
