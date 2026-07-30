import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcDisplayPanel extends ConsumerStatefulWidget {
  const RcDisplayPanel({super.key});

  @override
  ConsumerState<RcDisplayPanel> createState() => _RcDisplayPanelState();
}

class _RcDisplayPanelState extends ConsumerState<RcDisplayPanel> {
  final _backlightController = TextEditingController(text: '255');

  @override
  void dispose() {
    _backlightController.dispose();
    super.dispose();
  }

  void _setBacklight() {
    final raw = int.tryParse(_backlightController.text) ?? 255;
    final level = raw.clamp(0, 255);
    _backlightController.text = level.toString();
    sendBoardCommand(
      ref,
      context,
      'echo $level > /sys/class/backlight/*/brightness',
    );
  }

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              btn(Icons.list, 'DRM connectors', 'ls -al /sys/class/drm'),
              btn(
                Icons.tune,
                'DRM modes',
                'cat /sys/class/drm/*/modes 2>/dev/null',
              ),
              btn(
                Icons.brightness_6,
                'Backlight Status',
                'cat /sys/class/backlight/*/brightness',
              ),
              SizedBox(
                width: 150,
                height: 40,
                child: TextField(
                  controller: _backlightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Backlight (0-255)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _setBacklight(),
                ),
              ),
              PanelActionButton(
                icon: Icons.brightness_medium,
                label: 'Set Backlight',
                tooltipStr: 'echo level > /sys/class/backlight/*/brightness',
                onPressed: _setBacklight,
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.monitor,
          title: 'Display log check',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              btn(
                Icons.list,
                'dmesg',
                'dmesg | grep -iE "rk628|lvds|hdmi|panel|post.process"',
              ),
              btn(Icons.tune, 'ls rk628', 'ls -l /sys/kernel/debug/rk628/'),
              btn(
                Icons.brightness_6,
                'cat rk628',
                'cat /sys/kernel/debug/rk628/*/* 2>/dev/null',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
