import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/bluetooth/ble_command.dart';
import 'package:sanc_term/features/panels/bluetooth/providers/ble_notifier.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Nordic Thingy:53 (nRF5340) test & control panel. Exercises the EVM's
/// sensors, RGB LED, buzzer and BLE stack through the Zephyr shell over the
/// active serial pane, and drives the same BLE (`bt` shell) so a host/phone can
/// pair with it. Sensor/LED device names follow the Thingy:53 devicetree
/// labels; the custom-command field covers anything a specific firmware renames.
class Thingy53Panel extends ConsumerStatefulWidget {
  const Thingy53Panel({super.key});

  @override
  ConsumerState<Thingy53Panel> createState() => _Thingy53PanelState();
}

class _Thingy53PanelState extends ConsumerState<Thingy53Panel> {
  // Zephyr led shell device + RGB channel (Thingy:53 RGB LED).
  static const _ledDev = 'leds';
  static const _ledIdx = '0';

  final _name = TextEditingController(text: 'Thingy53-Sanc');
  final _custom = TextEditingController();
  final _bleCmd = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    _bleCmd.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(String label, String cmd, String tip, [IconData? icon]) =>
      PanelActionButton(
        icon: icon ?? Icons.bolt,
        label: label,
        tooltipStr: tip,
        onPressed: () => _send(cmd),
      );

  /// A NUS control button — sends [cmd] over BLE, disabled when not connected.
  PanelActionButton _bleBtn(
    String label,
    String cmd,
    String tip,
    bool connected, [
    IconData? icon,
  ]) =>
      PanelActionButton(
        icon: icon ?? Icons.bluetooth,
        label: label,
        tooltipStr: tip,
        onPressed: connected ? () => sendBleCommand(ref, context, cmd) : null,
      );

  // Zephyr led shell: `led set_color <dev> <led> <n> r g b`.
  PanelActionButton _color(String label, int r, int g, int b) => PanelActionButton(
        icon: Icons.circle,
        label: label,
        tooltipStr: 'RGB $r,$g,$b',
        onPressed: () => _send('led set_color $_ledDev $_ledIdx 3 $r $g $b'),
      );

  @override
  Widget build(BuildContext context) {
    final bleConnected = ref.watch(bleConnectedProvider);
    final txSubscribed = ref.watch(
      bleNotifierProvider.select((s) => s.subscribed.contains(NusUuids.tx)),
    );
    return MyPanel(
      icon: Icons.developer_board,
      panelTitle: 'Nordic Thingy:53',
      panelSubtitle: 'nRF5340 sensor, LED & BLE test over serial',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.memory,
          title: 'Board',
          subtitle: 'Zephyr system introspection',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Version', 'kernel version', 'Zephyr kernel version'),
              _btn('Uptime', 'kernel uptime', 'Milliseconds since boot'),
              _btn('Devices', 'device list', 'List registered devices'),
              _btn('Reboot', 'kernel reboot cold', 'Cold reboot the SoC'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.sensors,
          title: 'Sensors',
          subtitle: 'Read via the Zephyr sensor shell',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('BME688', 'sensor get bme688',
                  'Temperature / humidity / pressure / gas'),
              _btn('BMI270', 'sensor get bmi270', 'Accelerometer + gyroscope'),
              _btn('BMM150', 'sensor get bmm150', 'Magnetometer'),
              _btn('ADXL362', 'sensor get adxl362', 'Low-power accelerometer'),
              _btn('BH1749', 'sensor get bh1749', 'Colour / ambient light'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.lightbulb,
          title: 'RGB LED',
          subtitle: 'led shell — device "$_ledDev", channel $_ledIdx',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _color('Red', 255, 0, 0),
              _color('Green', 0, 255, 0),
              _color('Blue', 0, 0, 255),
              _color('White', 255, 255, 255),
              _btn('On', 'led on $_ledDev $_ledIdx', 'Turn LED on',
                  Icons.light_mode),
              _btn('Off', 'led off $_ledDev $_ledIdx', 'Turn LED off',
                  Icons.dark_mode),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.bluetooth,
          title: 'Bluetooth (device shell)',
          subtitle: 'Advertise over serial so a host can connect',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn('Init', 'bt init', 'Enable the Bluetooth stack'),
                  _btn('Adv On', 'bt advertise on', 'Start connectable adv'),
                  _btn('Adv Off', 'bt advertise off', 'Stop advertising'),
                  _btn('Info', 'bt info', 'Controller & connection info'),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: TextField(
                      controller: _name,
                      style: const TextStyle(fontFamily: 'Consolas'),
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
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
          icon: Icons.bluetooth_audio,
          title: 'BLE Control (NUS)',
          subtitle: bleConnected
              ? 'Writes to Nordic UART Service (RX) on the connected device'
              : 'Connect in the Bluetooth LE panel to enable',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: txSubscribed
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    label: txSubscribed ? 'TX Notifying' : 'Subscribe TX',
                    tooltipStr: 'Enable NUS TX notifications so device responses '
                        'appear in the BLE DATA terminal and Characteristic Data',
                    onPressed: bleConnected
                        ? () {
                            final n = ref.read(bleNotifierProvider.notifier);
                            if (txSubscribed) {
                              n.unsubscribeChar(NusUuids.service, NusUuids.tx);
                            } else {
                              n.subscribeChar(NusUuids.service, NusUuids.tx);
                            }
                          }
                        : null,
                  ),
                  _bleBtn('Help', 'help', 'Shell help over NUS', bleConnected),
                  _bleBtn('Uptime', 'kernel uptime', 'Milliseconds since boot',
                      bleConnected),
                  _bleBtn('LED On', 'led on $_ledDev $_ledIdx', 'Turn LED on',
                      bleConnected, Icons.light_mode),
                  _bleBtn('LED Off', 'led off $_ledDev $_ledIdx', 'Turn LED off',
                      bleConnected, Icons.dark_mode),
                  _bleBtn('Reboot', 'kernel reboot cold', 'Cold reboot',
                      bleConnected),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _bleCmd,
                        enabled: bleConnected,
                        style: const TextStyle(fontFamily: 'Consolas'),
                        decoration: const InputDecoration(
                          hintText: 'NUS command, e.g. led on leds 0',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        onSubmitted: (cmd) {
                          if (cmd.trim().isNotEmpty) {
                            sendBleCommand(ref, context, cmd);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send',
                    tooltipStr: 'Write the command to NUS RX',
                    onPressed: bleConnected
                        ? () {
                            final cmd = _bleCmd.text.trim();
                            if (cmd.isNotEmpty) sendBleCommand(ref, context, cmd);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.send,
          title: 'Custom Command',
          subtitle: 'Send a raw shell command',
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _custom,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'e.g. sensor get bme688',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (cmd) {
                      if (cmd.trim().isNotEmpty) _send(cmd);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PanelActionButton(
                icon: Icons.send,
                label: 'Send',
                tooltipStr: 'Send the command over the active pane',
                onPressed: () {
                  final cmd = _custom.text.trim();
                  if (cmd.isNotEmpty) _send(cmd);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
