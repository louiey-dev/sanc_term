import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Nordic nRF UART / shell quick-access. Talks to a Nordic device's console
/// over the active serial pane: Zephyr shell commands (nRF Connect SDK) plus
/// nRF91 modem AT commands routed through the `at_host` shell. Commands go out
/// with a CR terminator, which the Zephyr shell and `at_host` both accept.
class NrfUartPanel extends ConsumerStatefulWidget {
  const NrfUartPanel({super.key});

  @override
  ConsumerState<NrfUartPanel> createState() => _NrfUartPanelState();
}

class _NrfUartPanelState extends ConsumerState<NrfUartPanel> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
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
      icon: Icons.cable,
      panelTitle: 'Nordic UART / Shell',
      panelSubtitle: 'nRF Connect SDK (Zephyr) shell over serial',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.terminal,
          title: 'Zephyr Shell',
          subtitle: 'Kernel & device introspection',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Help', 'help', 'List available shell commands'),
              _btn('Version', 'kernel version', 'Zephyr kernel version'),
              _btn('Uptime', 'kernel uptime', 'Milliseconds since boot'),
              _btn('Threads', 'kernel threads', 'List running threads'),
              _btn('Stacks', 'kernel stacks', 'Per-thread stack usage'),
              _btn('Devices', 'device list', 'List registered devices'),
              _btn('Reboot', 'kernel reboot cold', 'Cold reboot the SoC'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.settings_input_antenna,
          title: 'nRF91 Modem (AT)',
          subtitle: 'AT commands via the at_host shell',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('CFUN?', 'AT+CFUN?', 'Query modem functional mode'),
              _btn('Online', 'AT+CFUN=1', 'Set modem to full functionality'),
              _btn('Offline', 'AT+CFUN=0', 'Power off the modem'),
              _btn('Flight', 'AT+CFUN=4', 'Flight mode (RF off)'),
              _btn('Firmware', 'AT+CGMR', 'Modem firmware version'),
              _btn('IMEI', 'AT+CGSN=1', 'Read device IMEI'),
              _btn('SysMode', 'AT%XSYSTEMMODE?', 'LTE-M / NB-IoT / GNSS mode'),
              _btn('Monitor', 'AT%XMONITOR', 'Network registration details'),
              _btn('Reg', 'AT+CEREG?', 'EPS registration status'),
              _btn('Operator', 'AT+COPS?', 'Current network operator'),
              _btn('Signal', 'AT+CESQ', 'Signal quality (RSRP/RSRQ)'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.send,
          title: 'Custom Command',
          subtitle: 'Send a raw shell or AT command',
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _custom,
                    style: const TextStyle(fontFamily: 'Consolas'),
                    decoration: const InputDecoration(
                      hintText: 'e.g. kernel uptime  or  AT+CFUN?',
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
