import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcUartPanel extends ConsumerWidget {
  const RcUartPanel({super.key});

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
      icon: Icons.cable,
      panelTitle: 'Rockchip UART',
      panelSubtitle: 'UART devices',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.cable,
          title: 'UART Devices',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'List UARTs', 'ls -al /dev/ttyS* /dev/ttyFIQ*'),
              btn(Icons.info_outline, 'tty', 'ls -al /dev/tty*'),
              btn(Icons.terminal, 'Console args', 'cat /proc/cmdline'),
            ],
          ),
        ),
      ],
    );
  }
}
