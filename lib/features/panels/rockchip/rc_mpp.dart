import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcMppPanel extends ConsumerWidget {
  const RcMppPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PanelActionButton btn(IconData i, String label, String cmd, String tip) =>
        PanelActionButton(
          icon: i,
          label: label,
          tooltipStr: tip,
          onPressed: () => sendBoardCommand(ref, context, cmd),
        );
    return MyPanel(
      icon: Icons.video_settings,
      panelTitle: 'Rockchip MPP',
      panelSubtitle: 'Media Process Platform service status',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.video_settings,
          title: 'MPP Service',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.bar_chart, 'Load', 'cat /proc/mpp_service/load',
                  'MPP work load'),
              btn(Icons.info_outline, 'Sessions',
                  'cat /proc/mpp_service/sessions-summary', 'MPP sessions/PIDs'),
              btn(Icons.countertops, 'TaskCount',
                  'cat /proc/mpp_service/rkvdec-core0/task_count',
                  'cumulative tasks processed'),
              btn(Icons.info_outline, 'SessionBuffers',
                  'cat /proc/mpp_service/rkvdec-core0/session_buffers',
                  'allocated buffers'),
              btn(Icons.device_hub, 'SupportsDevice',
                  'cat /proc/mpp_service/supports-device',
                  'supported hardware units'),
              btn(Icons.thermostat, 'Thermal',
                  'cat /sys/class/thermal/thermal_zone*/temp',
                  'thermal zones temp'),
            ],
          ),
        ),
      ],
    );
  }
}
