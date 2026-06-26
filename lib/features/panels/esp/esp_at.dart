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
          child: Wrap(
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
          ),
        ),
        MyPanelBody(
          icon: Icons.wifi,
          title: 'Wi-Fi AT Commands',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Mode?', 'AT+CWMODE?', 'Query Wi-Fi mode'),
              _btn('Station', 'AT+CWMODE=1', 'Set station mode'),
              _btn('Scan', 'AT+CWLAP', 'List nearby APs'),
              _btn('Current AP', 'AT+CWJAP?', 'Connected AP info'),
              _btn('Local IP', 'AT+CIFSR', 'Show local IP'),
            ],
          ),
        ),
      ],
    );
  }
}
