import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcDisplayPanel extends ConsumerWidget {
  const RcDisplayPanel({super.key});

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
      icon: Icons.monitor,
      panelTitle: 'Rockchip Display',
      panelSubtitle: 'DRM / framebuffer / backlight status',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.monitor,
          title: 'Display Status',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'DRM connectors', 'ls -al /sys/class/drm'),
              btn(Icons.aspect_ratio, 'FB size',
                  'cat /sys/class/graphics/fb0/virtual_size'),
              btn(Icons.tune, 'DRM modes',
                  'cat /sys/class/drm/*/modes 2>/dev/null'),
              btn(Icons.brightness_6, 'Backlight',
                  'cat /sys/class/backlight/*/brightness'),
            ],
          ),
        ),
      ],
    );
  }
}
