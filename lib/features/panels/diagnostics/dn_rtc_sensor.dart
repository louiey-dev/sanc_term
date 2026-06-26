import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnRtcSensorPanel extends ConsumerWidget {
  const DnRtcSensorPanel({super.key});

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
      icon: Icons.schedule,
      panelTitle: 'RTC / WDT / Sensor',
      panelSubtitle: 'Real-time clock, watchdog and thermal sensors',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.watch,
          title: 'Real-Time Clock',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.access_time, 'Read RTC', 'hwclock -r'),
              btn(Icons.list, 'RTC devices', 'ls -l /dev/rtc* 2>/dev/null'),
              btn(Icons.info, 'RTC info',
                  'cat /proc/driver/rtc 2>/dev/null'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.timer,
          title: 'Watchdog',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'WDT devices',
                  'ls -l /dev/watchdog* 2>/dev/null'),
              btn(Icons.info, 'WDT info',
                  'cat /sys/class/watchdog/*/identity 2>/dev/null'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.thermostat,
          title: 'Thermal Sensors',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.device_thermostat, 'Zone temps',
                  'cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null'),
              btn(Icons.label, 'Zone types',
                  'cat /sys/class/thermal/thermal_zone*/type 2>/dev/null'),
              btn(Icons.sensors, 'sensors', 'sensors'),
            ],
          ),
        ),
      ],
    );
  }
}
