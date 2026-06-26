import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcUsbPanel extends ConsumerWidget {
  const RcUsbPanel({super.key});

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
      icon: Icons.usb,
      panelTitle: 'Rockchip USB',
      panelSubtitle: 'USB devices and ports',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.usb,
          title: 'USB Devices',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.usb, 'lsusb', 'lsusb'),
              btn(Icons.account_tree_outlined, 'Tree', 'lsusb -t'),
              btn(Icons.list, 'Devices', 'ls -al /sys/bus/usb/devices'),
              btn(Icons.bug_report_outlined, 'USB dmesg',
                  'dmesg | grep -i usb | tail -n 40'),
            ],
          ),
        ),
      ],
    );
  }
}
