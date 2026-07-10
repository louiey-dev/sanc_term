import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Nordic nRF Bluetooth control. Drives a Nordic device's BLE stack through the
/// Zephyr `bt` shell over the active serial pane (the device is the BLE
/// peripheral/central — the host just issues shell commands). Run `Init` once
/// after boot before scanning or advertising.
class NrfBlePanel extends ConsumerStatefulWidget {
  const NrfBlePanel({super.key});

  @override
  ConsumerState<NrfBlePanel> createState() => _NrfBlePanelState();
}

class _NrfBlePanelState extends ConsumerState<NrfBlePanel> {
  final _name = TextEditingController(text: 'nRF-Sanc');
  // Peer address for `bt connect`: address + type (e.g. `public` / `random`).
  final _addr = TextEditingController();
  String _addrType = 'random';

  @override
  void dispose() {
    _name.dispose();
    _addr.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(String label, String cmd, String tip) =>
      PanelActionButton(
        icon: Icons.bolt,
        label: label,
        tooltipStr: tip,
        onPressed: () => _send(cmd),
      );

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.bluetooth,
      panelTitle: 'Nordic Bluetooth',
      panelSubtitle: 'Zephyr bt shell control over serial',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.power_settings_new,
          title: 'Controller',
          subtitle: 'Initialise before scanning or advertising',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Init', 'bt init', 'Enable the Bluetooth stack'),
              _btn('ID Show', 'bt id-show', 'Show local identity addresses'),
              _btn('ID Create', 'bt id-create', 'Create a new identity'),
              _btn('Info', 'bt info', 'Controller & connection info'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.bluetooth_searching,
          title: 'Scan',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Scan On', 'bt scan on', 'Start active scanning'),
              _btn('Passive', 'bt scan passive', 'Start passive scanning'),
              _btn('Scan Off', 'bt scan off', 'Stop scanning'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.wifi_tethering,
          title: 'Advertise',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn('Adv On', 'bt advertise on', 'Start connectable adv'),
                  _btn('Adv NC', 'bt advertise nconn',
                      'Non-connectable advertising'),
                  _btn('Adv Off', 'bt advertise off', 'Stop advertising'),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_name, 'Device name', 180),
                  PanelActionButton(
                    icon: Icons.drive_file_rename_outline,
                    label: 'Set Name',
                    tooltipStr: 'bt name <name>',
                    onPressed: () {
                      final n = _name.text.trim();
                      if (n.isNotEmpty) _send('bt name $n');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.link,
          title: 'Connection',
          subtitle: 'Address from the scan results (bt scan on)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _field(_addr, 'Peer address (AA:BB:…)', 200),
              DropdownButton<String>(
                value: _addrType,
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('public')),
                  DropdownMenuItem(value: 'random', child: Text('random')),
                ],
                onChanged: (v) => setState(() => _addrType = v ?? 'random'),
              ),
              PanelActionButton(
                icon: Icons.bluetooth_connected,
                label: 'Connect',
                tooltipStr: 'bt connect <addr> <type>',
                onPressed: () {
                  final a = _addr.text.trim();
                  if (a.isNotEmpty) _send('bt connect $a $_addrType');
                },
              ),
              _btn('Disconnect', 'bt disconnect', 'Drop the active connection'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, double width) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Consolas'),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }
}
