import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvUartPanel extends ConsumerStatefulWidget {
  const NvUartPanel({super.key});

  @override
  ConsumerState<NvUartPanel> createState() => _NvUartPanelState();
}

class _NvUartPanelState extends ConsumerState<NvUartPanel> {
  static const _bauds = [
    '9600', '19200', '38400', '57600', '115200',
    '230400', '460800', '921600', '1500000',
  ];

  final _port = TextEditingController(text: 'ttyTHS1');
  final _msg = TextEditingController();
  String _baud = '115200';

  @override
  void dispose() {
    _port.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.cable,
      panelTitle: 'nVidia UART',
      panelSubtitle: 'UART configuration and base info',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.info_outline,
          title: 'UART Information',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _field(_port, 'Port (e.g. ttyTHS1)', 150),
              PanelActionButton(
                icon: Icons.list,
                label: 'List UARTs',
                tooltipStr: 'ls -al /dev/tty*',
                onPressed: () => sendBoardCommand(ref, context, 'ls -al /dev/tty*'),
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.tune,
          title: 'UART Control',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildDropdown<String>(
                    context,
                    value: _baud,
                    items: _bauds
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _baud = v ?? '115200'),
                    width: 110,
                  ),
                  PanelActionButton(
                    icon: Icons.open_in_new,
                    label: 'Open UART',
                    tooltipStr: 'stty configure port',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo stty -F /dev/${_port.text} $_baud raw -echo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_msg, 'Message', 250),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send',
                    tooltipStr: 'write message to port',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'echo "${_msg.text}" | sudo tee /dev/${_port.text}',
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.message,
                    label: 'Read',
                    tooltipStr: 'read from port',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo cat /dev/${_port.text}',
                    ),
                  ),
                ],
              ),
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
