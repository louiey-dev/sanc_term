import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// ESP-AT command quick-access. Commands are sent over the active serial pane
/// with a CRLF terminator (ESP-AT requirement).
class EspAtPanel extends ConsumerStatefulWidget {
  const EspAtPanel({super.key});

  @override
  ConsumerState<EspAtPanel> createState() => _EspAtPanelState();
}

class _EspAtPanelState extends ConsumerState<EspAtPanel> {
  bool _echoOn = true;
  final _wifiSsid = TextEditingController();
  final _wifiPasswd = TextEditingController();
  final _apSsid = TextEditingController();
  final _apPasswd = TextEditingController();

  void _at(String cmd) =>
      sendBoardCommand(ref, context, cmd, terminator: '\r\n');

  PanelActionButton _btn(String label, String cmd, String tip) =>
      PanelActionButton(
        icon: Icons.bolt,
        label: label,
        tooltipStr: tip,
        onPressed: () => _at(cmd),
      );

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.wifi,
      panelTitle: 'ESP AT Commands',
      panelSubtitle: 'AT command quick access panel',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.bolt,
          title: 'Basic AT Commands',
          child: _bacisCommand(),
        ),
        MyPanelBody(
          icon: Icons.wifi,
          title: 'Wi-Fi AT Commands',
          child: _wifiCommand(),
        ),
      ],
    );
  }

  _bacisCommand() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _btn('AT', 'AT', 'Test AT startup'),
        _btn('RST', 'AT+RST', 'Restart the module'),
        _btn('GMR', 'AT+GMR', 'Version information'),
        _btn('CMDs', 'AT+CMD?', 'List supported AT commands'),
        _btn('GSLP', 'AT+GSLP', 'Enter deep-sleep'),
        PanelActionButton(
          icon: Icons.repeat,
          label: _echoOn ? 'ECHO OFF' : 'ECHO ON',
          tooltipStr: 'Toggle AT command echo',
          onPressed: () {
            _at(_echoOn ? 'ATE0' : 'ATE1');
            setState(() => _echoOn = !_echoOn);
          },
        ),
        _btn('RESTORE', 'AT+RESTORE', 'Restore factory defaults'),
        _btn('UART_CUR', 'AT+UART_CUR?', 'Current UART config'),
        _btn('UART_DEF', 'AT+UART_DEF?', 'Default UART config'),
        _btn('SLEEP?', 'AT+SLEEP?', 'Get sleep mode'),
        _btn('SLEEP', 'AT+SLEEP=1', 'Set sleep mode'),
      ],
    );
  }

  _wifiCommand() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 30,
                  width: 200,
                  child: TextField(
                    controller: _wifiSsid,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'wifi ssid',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (cmd) {
                      sendBoardCommand(ref, context, cmd, terminator: '\r\n');
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 200,
                  child: TextField(
                    controller: _wifiPasswd,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'password',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (cmd) {
                      sendBoardCommand(ref, context, cmd, terminator: '\r\n');
                    },
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _btn(
                      'Init?',
                      'AT+CWINIT?',
                      'Query the Wi-Fi initialization status of ESP32 device',
                    ),
                    _btn(
                      'Init',
                      'AT+CWINIT=1',
                      'Initialize Wi-Fi driver of ESP32 device',
                    ),
                    _btn(
                      'De-Init',
                      'AT+CWINIT=0',
                      'Deinitialize Wi-Fi driver of ESP32 device',
                    ),
                    _btn(
                      'Mode?',
                      'AT+CWMODE?',
                      'Query Wi-Fi mode(Station/SoftAP/Station+SoftAP)',
                    ),
                    _btn('Station', 'AT+CWMODE=1', 'Set station mode'),
                    _btn('State', 'AT+CWSTATE?', 'Query Wi-Fi state'),
                    _btn(
                      'Connect',
                      'AT+CWJAP="${_wifiSsid.text}","${_wifiPasswd.text}"',
                      'Connect to target AP',
                    ),
                    _btn('Connect?', 'AT+CWJAP?', 'Query current connected AP'),
                    _btn(
                      'Disconnect',
                      'AT+CWQAP',
                      'Disconnect from current AP',
                    ),
                    _btn('Scan', 'AT+CWLAP', 'List nearby APs'),
                    _btn('Current AP', 'AT+CWJAP?', 'Connected AP info'),
                    _btn('Local IP', 'AT+CIFSR', 'Show local IP'),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 30,
                  width: 200,
                  child: TextField(
                    controller: _apSsid,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'AP ssid',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (cmd) {
                      sendBoardCommand(ref, context, cmd, terminator: '\r\n');
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 200,
                  child: TextField(
                    controller: _apPasswd,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'password',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (cmd) {
                      sendBoardCommand(ref, context, cmd, terminator: '\r\n');
                    },
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        _btn(
                          'AP?',
                          'AT+CWSAP?',
                          'Query the configuration parameters',
                        ),
                        _btn(
                          'AP?',
                          'AT+CWSAP?',
                          'Query the configuration parameters',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
