import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/utils/my_utils.dart';
import 'package:sanc_term/features/panels/bluetooth/ble_command.dart';
import 'package:sanc_term/features/panels/bluetooth/providers/ble_notifier.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

final gBleCmd = TextEditingController();

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

  // Swatches for the RGB LED PWM colour palette.
  static const _palette = <Color>[
    Color(0xFFFF0000), // red
    Color(0xFFFF7F00), // orange
    Color(0xFFFFFF00), // yellow
    Color(0xFF7FFF00), // chartreuse
    Color(0xFF00FF00), // green
    Color(0xFF00FF7F), // spring green
    Color(0xFF00FFFF), // cyan
    Color(0xFF007FFF), // azure
    Color(0xFF0000FF), // blue
    Color(0xFF7F00FF), // violet
    Color(0xFFFF00FF), // magenta
    Color(0xFFFF007F), // rose
    Color(0xFFFFFFFF), // white
    Color(0xFF000000), // off
  ];

  final _name = TextEditingController(text: 'Thingy53-Sanc');
  final _custom = TextEditingController();

  // GPIO Control inputs.
  final _pmicIset = TextEditingController(text: '100');
  final _buzzFreq = TextEditingController(text: '1000');
  final _buzzDur = TextEditingController(text: '200');
  // RGB LED PWM brightness (0.0–1.0) applied by the R/G/B buttons.
  double _pwmBright = 1.0;
  String _bleSendMode = 'text';

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    // gBleCmd.dispose();
    _pmicIset.dispose();
    _buzzFreq.dispose();
    _buzzDur.dispose();
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

  PanelActionButton _scaleBtn(int index, String label) => PanelActionButton(
    icon: Icons.music_note,
    label: label,
    tooltipStr: 'buzzer scale $index [duration]',
    onPressed: () {
      final d = _buzzDur.text.trim();
      if (d.isNotEmpty) {
        _send('buzzer scale $index $d');
      } else {
        _send('buzzer scale $index');
      }
    },
  );

  /// A NUS control button — sends [cmd] over BLE, disabled when not connected.
  PanelActionButton _bleBtn(
    String label,
    String cmd,
    String tip,
    bool connected, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.bluetooth,
    label: label,
    tooltipStr: tip,
    onPressed: connected ? () => sendBleCommand(ref, context, cmd) : null,
  );

  /// A colour-palette swatch. Tapping sends `led_pwm color r g b <brightness>`,
  /// where r/g/b and brightness are all floats in 0.0–1.0.
  Widget _swatch(Color color) {
    final r = color.r.toStringAsFixed(2);
    final g = color.g.toStringAsFixed(2);
    final b = color.b.toStringAsFixed(2);
    final cmd = 'led_pwm color $r $g $b ${_pwmBright.toStringAsFixed(2)}';
    return Tooltip(
      message: cmd,
      child: InkWell(
        onTap: () => _send(cmd),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
          ),
        ),
      ),
    );
  }

  /// A per-channel PWM button that applies the current brightness slider value:
  /// `led_pwm <ch> <0.00–1.00>`.
  PanelActionButton _pwmChannel(String label, String ch) => PanelActionButton(
    icon: Icons.circle,
    label: label,
    tooltipStr: 'led_pwm $ch ${_pwmBright.toStringAsFixed(2)}',
    onPressed: () => _send('led_pwm $ch ${_pwmBright.toStringAsFixed(2)}'),
  );

  /// On/Off pair for an active-high enable signal `<base> 1|0`.
  List<Widget> _enable(String label, String base) => [
    _btn('$label On', '$base 1', '$base 1', Icons.toggle_on),
    _btn('$label Off', '$base 0', '$base 0', Icons.toggle_off_outlined),
  ];

  /// Compact numeric input used by the PMIC/buzzer controls.
  Widget _numField(
    TextEditingController c,
    String label, {
    double width = 130,
  }) => SizedBox(
    width: width,
    height: 40,
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontFamily: 'Consolas'),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    ),
  );

  /// Sub-heading that groups related GPIO controls within the section.
  Widget _gpioLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
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
              _btn('Reboot', 'sys reset 1000', 'Cold reboot the SoC'),
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
              _btn(
                'BME688 Init',
                'sensor bme688 init',
                'Temperature / humidity / pressure / gas',
              ),
              _btn(
                'BME688 Read',
                'sensor bme688 read',
                'Temperature / humidity / pressure / gas',
              ),
              _btn(
                'BMI270 Init',
                'sensor bmi270 init',
                'Accelerometer + gyroscope',
              ),
              _btn(
                'BMI270 Read',
                'sensor bmi270 read',
                'Accelerometer + gyroscope',
              ),
              _btn('BMM150 Init', 'sensor bmm150 init', 'Magnetometer'),
              _btn('BMM150 Read', 'sensor bmm150 read', 'Magnetometer'),
              _btn(
                'ADXL362 Init',
                'sensor adxl362 init',
                'Low-power accelerometer',
              ),
              _btn(
                'ADXL362 Read',
                'sensor adxl362 read',
                'Low-power accelerometer',
              ),
              _btn(
                'BH1749 Init',
                'sensor bh1749 init',
                'Colour / ambient light',
              ),
              _btn(
                'BH1749 Read',
                'sensor bh1749 read',
                'Colour / ambient light',
              ),
            ],
          ),
        ),
        // MyPanelBody(
        //   icon: Icons.lightbulb,
        //   title: 'RGB LED',
        //   subtitle: 'led shell — device "$_ledDev", channel $_ledIdx',
        //   child: Wrap(
        //     spacing: 8,
        //     runSpacing: 8,
        //     children: [
        //       _color('Red', 255, 0, 0),
        //       _color('Green', 0, 255, 0),
        //       _color('Blue', 0, 0, 255),
        //       _color('White', 255, 255, 255),
        //       _btn(
        //         'On',
        //         'led on $_ledDev $_ledIdx',
        //         'Turn LED on',
        //         Icons.light_mode,
        //       ),
        //       _btn(
        //         'Off',
        //         'led off $_ledDev $_ledIdx',
        //         'Turn LED off',
        //         Icons.dark_mode,
        //       ),
        //     ],
        //   ),
        // ),
        MyPanelBody(
          icon: Icons.lightbulb,
          title: 'RGB LED PWM',
          subtitle: 'led_pwm — set brightness 0.0–1.0, then apply per channel',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Brightness'),
                  Expanded(
                    child: Slider(
                      value: _pwmBright,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: _pwmBright.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _pwmBright = v),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      _pwmBright.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Consolas'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _gpioLabel('Palette (R/G/B)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final c in _palette) _swatch(c)],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pwmChannel('Red', 'r'),
                  _pwmChannel('Green', 'g'),
                  _pwmChannel('Blue', 'b'),
                  _btn('On', 'led_pwm on', 'Turn LED on', Icons.light_mode),
                  _btn('Off', 'led_pwm off', 'Turn LED off', Icons.dark_mode),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.electrical_services,
          title: 'GPIO Control',
          subtitle:
              'FEM, PMIC, power rails, buzzer & battery '
              '(commands shown in each tooltip)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _gpioLabel('Front-end module (nRF21540)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._enable('Mode', 'gpio fem 0'),
                  ..._enable('RX', 'gpio fem 1'),
                  ..._enable('TX', 'gpio fem 2'),
                  ..._enable('Sel', 'gpio fem 3'),
                ],
              ),
              const SizedBox(height: 12),
              _gpioLabel('Power rails'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._enable('3V3', 'gpio 3v set'),
                  ..._enable('Sensor Pwr', 'gpio sens set'),
                ],
              ),
              const SizedBox(height: 12),
              _gpioLabel('PMIC (nPM1100)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _numField(_pmicIset, 'ISET (mA)'),
                  PanelActionButton(
                    icon: Icons.tune,
                    label: 'Set ISET',
                    tooltipStr: 'pmic iset <mA>',
                    onPressed: () {
                      final v = _pmicIset.text.trim();
                      if (v.isNotEmpty) _send('pmic iset $v');
                    },
                  ),
                  _btn(
                    'Err Status',
                    'pmic err',
                    'Read charger error (pmic err)',
                    Icons.report_gmailerrorred,
                  ),
                  _btn(
                    'Charge Status',
                    'pmic chg',
                    'Read charging status (pmic chg)',
                    Icons.battery_charging_full,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _gpioLabel('Buzzer (PWM)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _numField(_buzzFreq, 'Frequency (Hz)', width: 150),
                  _numField(_buzzDur, 'Duration (ms)', width: 150),
                  PanelActionButton(
                    icon: Icons.volume_up,
                    label: 'Beep',
                    tooltipStr: 'Play a short beep',
                    onPressed: () {
                      final f = _buzzFreq.text.trim();
                      final d = _buzzDur.text.trim();
                      if (f.isNotEmpty && d.isNotEmpty) {
                        _send('buzzer beep $f $d');
                      }
                    },
                  ),
                  PanelActionButton(
                    icon: Icons.volume_up,
                    label: 'Tone',
                    tooltipStr: 'Play a tone at a specific frequency',
                    onPressed: () {
                      final f = _buzzFreq.text.trim();
                      final d = _buzzDur.text.trim();
                      if (f.isNotEmpty && d.isNotEmpty) _send('buzzer tone $f');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _scaleBtn(0, 'Do'),
                  _scaleBtn(1, 'Rae'),
                  _scaleBtn(2, 'Mi'),
                  _scaleBtn(3, 'Pa'),
                  _scaleBtn(4, 'Sol'),
                  _scaleBtn(5, 'Ra'),
                  _scaleBtn(6, 'Si'),
                  _scaleBtn(7, 'Do'),
                ],
              ),
              const SizedBox(height: 12),
              _gpioLabel('Battery'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn(
                    'Read Battery',
                    'adc r_mv',
                    'Read battery voltage / level',
                    Icons.battery_full,
                  ),
                ],
              ),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
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
                    tooltipStr:
                        'Enable NUS TX notifications so device responses '
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
                  _bleBtn(
                    'Uptime',
                    'kernel uptime',
                    'Milliseconds since boot',
                    bleConnected,
                  ),
                  _bleBtn(
                    'LED On',
                    'led on $_ledDev $_ledIdx',
                    'Turn LED on',
                    bleConnected,
                    Icons.light_mode,
                  ),
                  _bleBtn(
                    'LED Off',
                    'led off $_ledDev $_ledIdx',
                    'Turn LED off',
                    bleConnected,
                    Icons.dark_mode,
                  ),
                  _bleBtn(
                    'Reboot',
                    'kernel reboot cold',
                    'Cold reboot',
                    bleConnected,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  buildDropdown<String>(
                    context,
                    value: _bleSendMode,
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'hex', child: Text('Hex')),
                    ],
                    onChanged: bleConnected
                        ? (v) {
                            if (v != null) {
                              setState(() => _bleSendMode = v);
                            }
                          }
                        : null,
                    width: 75,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: gBleCmd,
                        enabled: bleConnected,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Consolas',
                        ),
                        decoration: InputDecoration(
                          hintText: _bleSendMode == 'text'
                              ? 'NUS command, e.g. led on leds 0'
                              : 'Hex bytes, e.g. 00 11 22 or 0xAA 0xBB',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (cmd) {
                          _handleBleSend(cmd);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send',
                    tooltipStr: 'Write to NUS RX',
                    onPressed: bleConnected
                        ? () {
                            _handleBleSend(gBleCmd.text);
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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

  void _handleBleSend(String raw) {
    if (_bleSendMode == 'text') {
      final cmd = raw.trim();
      if (cmd.isNotEmpty) {
        sendBleCommand(ref, context, cmd);
      }
    } else {
      final cleanRaw = raw.trim();
      if (cleanRaw.isEmpty) return;
      final bytes = _parseHexString(cleanRaw);
      if (bytes == null) {
        myUtils.showErrorSnackbar(context, 'Invalid hex string format');
        return;
      }
      sendBleWrite(ref, context, NusUuids.service, NusUuids.rx, bytes);
    }
  }

  Uint8List? _parseHexString(String hex) {
    final clean = hex
        .replaceAll(RegExp(r'0[xX]'), '')
        .replaceAll(RegExp(r'[\s,;\-\\:\x00]'), '');

    if (clean.isEmpty) return Uint8List(0);
    if (clean.length % 2 != 0) {
      return null;
    }

    try {
      final bytes = Uint8List(clean.length ~/ 2);
      for (var i = 0; i < clean.length; i += 2) {
        final hexChar = clean.substring(i, i + 2);
        final byte = int.parse(hexChar, radix: 16);
        bytes[i ~/ 2] = byte;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
