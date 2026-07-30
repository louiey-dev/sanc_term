import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// STM32 F746 Bluetooth LE (BLE) Panel / Sub Panel.
/// Provides control for BLE radio status, scan, advertise, connection & custom commands.
class F746BlePanel extends ConsumerStatefulWidget {
  final bool standalone;

  const F746BlePanel({super.key, this.standalone = true});

  @override
  ConsumerState<F746BlePanel> createState() => _F746BlePanelState();
}

class _F746BlePanelState extends ConsumerState<F746BlePanel> {
  // BLE Controllers
  final _bleAddr = TextEditingController(text: 'AA:BB:CC:DD:EE:FF');
  final _bleCmd = TextEditingController(text: 'status');

  @override
  void dispose() {
    _bleAddr.dispose();
    _bleCmd.dispose();

    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.bolt,
    label: label,
    tooltipStr: tip,
    onPressed: () => _send(cmd),
  );

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double width = 130,
    String? hint,
  }) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bodies = _buildPanelBodies();
    if (widget.standalone) {
      return MyPanel(
        icon: Icons.bluetooth,
        panelTitle: 'F746 BLE Panel',
        panelSubtitle:
            'Bluetooth Low Energy radio status, scan, advertise & connection',
        panelActions: const [],
        children: bodies,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < bodies.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          bodies[i],
        ],
      ],
    );
  }

  List<Widget> _buildPanelBodies() {
    return [
      MyPanelBody(
        icon: Icons.bluetooth,
        title: 'BLE — Bluetooth Low Energy Commands',
        subtitle:
            'Bluetooth LE radio status, scan, advertise & custom commands',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('BLE Radio Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Init Stack',
                  'ble init',
                  'Initialize Bluetooth stack',
                  Icons.bluetooth_searching,
                ),
                _btn(
                  'Status',
                  'ble status',
                  'Show BLE status',
                  Icons.info_outline,
                ),
                _btn(
                  'Scan On',
                  'ble scan on',
                  'Start BLE scan',
                  Icons.radar,
                ),
                _btn(
                  'Scan Off',
                  'ble scan off',
                  'Stop BLE scan',
                  Icons.bluetooth_disabled,
                ),
                _btn(
                  'Adv On',
                  'ble adv on',
                  'Start BLE advertising',
                  Icons.wifi_tethering,
                ),
                _btn(
                  'Adv Off',
                  'ble adv off',
                  'Stop BLE advertising',
                  Icons.wifi_tethering_off,
                ),
                _btn(
                  'Disconnect',
                  'ble disconnect',
                  'Disconnect BLE connection',
                  Icons.link_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Connect to BLE Device'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _bleAddr,
                  'MAC / Address',
                  width: 200,
                  hint: 'AA:BB:CC:DD:EE:FF',
                ),
                PanelActionButton(
                  icon: Icons.bluetooth_connected,
                  label: 'Connect BLE',
                  tooltipStr: 'ble connect <address>',
                  onPressed: () {
                    final addr = _bleAddr.text.trim();
                    if (addr.isNotEmpty) {
                      _send('ble connect $addr');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Custom BLE Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_bleCmd, 'Command', width: 220, hint: 'ble info'),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send BLE Cmd',
                  tooltipStr: 'Send raw BLE command',
                  onPressed: () {
                    final cmd = _bleCmd.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(cmd.startsWith('ble ') ? cmd : 'ble $cmd');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}
