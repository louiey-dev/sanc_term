import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnPowerPanel extends ConsumerWidget {
  const DnPowerPanel({super.key});

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
      icon: Icons.bolt,
      panelTitle: 'Power Monitor',
      panelSubtitle: 'Voltage, current and power-supply status',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.electric_bolt,
          title: 'Rail Sensors (hwmon)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.power, 'Voltage',
                  'cat /sys/class/hwmon/*/in*_input 2>/dev/null'),
              btn(Icons.electric_meter, 'Current',
                  'cat /sys/class/hwmon/*/curr*_input 2>/dev/null'),
              btn(Icons.flash_on, 'Power',
                  'cat /sys/class/hwmon/*/power*_input 2>/dev/null'),
              btn(Icons.label, 'Rail Names',
                  'cat /sys/class/hwmon/*/*_label 2>/dev/null'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.battery_charging_full,
          title: 'Power Supply',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'Supplies',
                  'ls /sys/class/power_supply 2>/dev/null'),
              btn(Icons.info, 'Supply Status',
                  'cat /sys/class/power_supply/*/uevent 2>/dev/null'),
            ],
          ),
        ),
      ],
    );
  }
}
