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
  // Device & Init Controllers
  final _bleDeviceName = TextEditingController(text: 'ESP32_BLE');

  // Advertising Controllers
  final _advMin = TextEditingController(text: '32');
  final _advMax = TextEditingController(text: '64');
  final _advType = TextEditingController(text: '0');
  final _advData = TextEditingController(text: '0201060303E0FF');

  // Scan Controller
  final _scanDuration = TextEditingController(text: '5');

  // Connection Controllers
  final _bleAddr = TextEditingController(text: 'AA:BB:CC:DD:EE:FF');
  final _disconnId = TextEditingController(text: '0');

  // Notification Controllers
  final _notifyConn = TextEditingController(text: '0');
  final _notifySrv = TextEditingController(text: '1');
  final _notifyAttr = TextEditingController(text: '1');
  final _notifyMsg = TextEditingController(text: 'Hello BLE');

  // Custom Cmd Controller
  final _bleCmd = TextEditingController(text: 'status');

  @override
  void dispose() {
    _bleDeviceName.dispose();
    _advMin.dispose();
    _advMax.dispose();
    _advType.dispose();
    _advData.dispose();
    _scanDuration.dispose();
    _bleAddr.dispose();
    _disconnId.dispose();
    _notifyConn.dispose();
    _notifySrv.dispose();
    _notifyAttr.dispose();
    _notifyMsg.dispose();
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
            'Bluetooth Low Energy status, init, adv, scan, GATT & connection',
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
      // Body 1: Subsystem & Device Control
      MyPanelBody(
        icon: Icons.bluetooth,
        title: 'BLE — Subsystem & Device Control',
        subtitle:
            'Initialize, status, de-init, MAC address, GATT server & device name',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('BLE Stack & Status Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Status',
                  'ble status',
                  'Show BLE subsystem status',
                  Icons.info_outline,
                ),
                _btn(
                  'Init Stack',
                  'ble init',
                  'Initialize BLE stack (ble init)',
                  Icons.power_settings_new,
                ),
                _btn(
                  'Init Client',
                  'ble init 1',
                  'Initialize BLE as Client (role 1)',
                  Icons.bluetooth_searching,
                ),
                _btn(
                  'Init Server',
                  'ble init 2',
                  'Initialize BLE as Server (role 2)',
                  Icons.dns,
                ),
                _btn(
                  'De-Init',
                  'ble deinit',
                  'De-initialize BLE (AT+BLEINIT=0)',
                  Icons.power_off,
                ),
                _btn(
                  'MAC Address',
                  'ble addr',
                  'Query BLE BD MAC address (AT+BLEADDR?)',
                  Icons.fingerprint,
                ),
                _btn(
                  'Create GATT Srv',
                  'ble gattsrv',
                  'Create GATT Server services (AT+BLEGATTSSRVCRE)',
                  Icons.room_preferences,
                ),
                _btn(
                  'Run Demo',
                  'ble demo',
                  'Run automated BLE demo sequence',
                  Icons.play_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('BLE Device Name'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Query Name',
                  'ble name',
                  'Query BLE device name',
                  Icons.badge,
                ),
                _inputField(
                  _bleDeviceName,
                  'Device Name',
                  width: 160,
                  hint: 'ESP32_BLE',
                ),
                PanelActionButton(
                  icon: Icons.edit,
                  label: 'Set Name',
                  tooltipStr: 'ble name <new_name>',
                  onPressed: () {
                    final name = _bleDeviceName.text.trim();
                    if (name.isNotEmpty) {
                      _send('ble name $name');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // Body 2: Advertising & Scanning
      MyPanelBody(
        icon: Icons.wifi_tethering,
        title: 'BLE — Advertising & Scanning',
        subtitle:
            'Configure BLE advertising parameters, raw adv data & device scanning',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('BLE Advertising Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Adv Start',
                  'ble adv start',
                  'Start BLE advertising',
                  Icons.wifi_tethering,
                ),
                _btn(
                  'Adv Stop',
                  'ble adv stop',
                  'Stop BLE advertising',
                  Icons.wifi_tethering_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('BLE Advertising Parameters'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_advMin, 'Min Int', width: 80, hint: '32'),
                _inputField(_advMax, 'Max Int', width: 80, hint: '64'),
                _inputField(_advType, 'Adv Type', width: 80, hint: '0'),
                PanelActionButton(
                  icon: Icons.tune,
                  label: 'Set Adv Params',
                  tooltipStr: 'ble advparam <min> <max> [type]',
                  onPressed: () {
                    final min = _advMin.text.trim();
                    final max = _advMax.text.trim();
                    final type = _advType.text.trim();
                    if (min.isNotEmpty && max.isNotEmpty) {
                      _send(
                        type.isNotEmpty
                            ? 'ble advparam $min $max $type'
                            : 'ble advparam $min $max',
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('BLE Advertising Raw Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _advData,
                  'Adv Hex Data',
                  width: 220,
                  hint: '0201060303E0FF',
                ),
                PanelActionButton(
                  icon: Icons.data_object,
                  label: 'Set Adv Data',
                  tooltipStr: 'ble advdata <hex_string>',
                  onPressed: () {
                    final hex = _advData.text.trim();
                    if (hex.isNotEmpty) {
                      _send('ble advdata $hex');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('BLE Device Scanner'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Scan Default',
                  'ble scan',
                  'Scan BLE devices (default duration)',
                  Icons.radar,
                ),
                _inputField(
                  _scanDuration,
                  'Duration (s)',
                  width: 90,
                  hint: '5',
                ),
                PanelActionButton(
                  icon: Icons.timer,
                  label: 'Scan (Timed)',
                  tooltipStr: 'ble scan [duration_sec]',
                  onPressed: () {
                    final dur = _scanDuration.text.trim();
                    _send(dur.isNotEmpty ? 'ble scan $dur' : 'ble scan');
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // Body 3: Connection, GATT & Custom Commands
      MyPanelBody(
        icon: Icons.bluetooth_connected,
        title: 'BLE — Connection, GATT & Commands',
        subtitle:
            'Connect, disconnect, send GATT notifications & raw commands',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Connect & Disconnect BLE Device'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _bleAddr,
                  'MAC Address',
                  width: 180,
                  hint: 'AA:BB:CC:DD:EE:FF',
                ),
                PanelActionButton(
                  icon: Icons.bluetooth_connected,
                  label: 'Connect BLE',
                  tooltipStr: 'ble connect <mac_addr>',
                  onPressed: () {
                    final addr = _bleAddr.text.trim();
                    if (addr.isNotEmpty) {
                      _send('ble connect $addr');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Disconnect All',
                  'ble disconnect',
                  'Disconnect BLE device (all)',
                  Icons.link_off,
                ),
                _inputField(_disconnId, 'Conn ID', width: 80, hint: '0'),
                PanelActionButton(
                  icon: Icons.link_off,
                  label: 'Disconnect ID',
                  tooltipStr: 'ble disconnect [conn_id]',
                  onPressed: () {
                    final id = _disconnId.text.trim();
                    _send(
                      id.isNotEmpty
                          ? 'ble disconnect $id'
                          : 'ble disconnect',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Send GATT Notification'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_notifyConn, 'Conn', width: 70, hint: '0'),
                _inputField(_notifySrv, 'Srv', width: 70, hint: '1'),
                _inputField(_notifyAttr, 'Attr', width: 70, hint: '1'),
                _inputField(_notifyMsg, 'Message', width: 160, hint: 'Hello'),
                PanelActionButton(
                  icon: Icons.notifications_active,
                  label: 'Send Notify',
                  tooltipStr: 'ble notify <conn> <srv> <attr> <msg>',
                  onPressed: () {
                    final c = _notifyConn.text.trim();
                    final s = _notifySrv.text.trim();
                    final a = _notifyAttr.text.trim();
                    final m = _notifyMsg.text.trim();
                    if (c.isNotEmpty &&
                        s.isNotEmpty &&
                        a.isNotEmpty &&
                        m.isNotEmpty) {
                      _send('ble notify $c $s $a $m');
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
                _inputField(
                  _bleCmd,
                  'Command',
                  width: 220,
                  hint: 'status',
                ),
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
