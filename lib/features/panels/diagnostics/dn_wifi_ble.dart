import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnWifiBlePanel extends ConsumerWidget {
  const DnWifiBlePanel({super.key});

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
      icon: Icons.wifi,
      panelTitle: 'WiFi / BLE',
      panelSubtitle: 'Wireless and Bluetooth connectivity',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.wifi,
          title: 'WiFi',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'Interfaces', 'iw dev'),
              btn(Icons.network_wifi, 'Link status', 'iw dev wlan0 link'),
              btn(Icons.search, 'Scan', 'iw dev wlan0 scan | grep SSID'),
              btn(Icons.settings_ethernet, 'nmcli', 'nmcli device status'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.bluetooth,
          title: 'Bluetooth / BLE',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.bluetooth, 'Controllers', 'hciconfig -a'),
              btn(Icons.devices, 'BT devices', 'bluetoothctl devices'),
              btn(Icons.toggle_on, 'rfkill list', 'rfkill list'),
            ],
          ),
        ),
      ],
    );
  }
}
