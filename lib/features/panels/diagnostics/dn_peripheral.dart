import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnPeripheralPanel extends ConsumerWidget {
  const DnPeripheralPanel({super.key});

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
      panelTitle: 'Peripheral Check',
      panelSubtitle: 'UART, I2C, SPI, Ethernet and USB buses',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.usb,
          title: 'Serial & USB',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.cable, 'TTY devices', 'ls -l /dev/tty* 2>/dev/null'),
              btn(Icons.usb, 'lsusb', 'lsusb'),
              btn(Icons.account_tree, 'USB tree', 'lsusb -t'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.developer_board,
          title: 'I2C & SPI',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'I2C buses', 'i2cdetect -l'),
              btn(Icons.grid_on, 'I2C scan (bus 1)', 'i2cdetect -y 1'),
              btn(Icons.memory, 'SPI devices', 'ls -l /dev/spidev* 2>/dev/null'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.lan,
          title: 'Ethernet',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'Links', 'ip link show'),
              btn(Icons.lan, 'Addresses', 'ip addr show'),
            ],
          ),
        ),
      ],
    );
  }
}
