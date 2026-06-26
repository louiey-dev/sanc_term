import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcI2cPanel extends ConsumerWidget {
  const RcI2cPanel({super.key});

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
      icon: Icons.cable,
      panelTitle: 'Rockchip I2C',
      panelSubtitle: 'I2C buses and RTC',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.schedule,
          title: 'RTC',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.calendar_today, 'Date', 'cat /sys/class/rtc/rtc0/date'),
              btn(Icons.access_time, 'Time', 'cat /sys/class/rtc/rtc0/time'),
              btn(Icons.watch_later_outlined, 'hwclock', 'hwclock --show'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.cable,
          title: 'I2C Buses',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'List buses', 'i2cdetect -l'),
              btn(Icons.search, 'Scan bus 1', 'sudo i2cdetect -y 1'),
            ],
          ),
        ),
      ],
    );
  }
}
