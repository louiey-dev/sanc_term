import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class CmGeneralSettingsPanel extends ConsumerWidget {
  const CmGeneralSettingsPanel({super.key});

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
      icon: Icons.settings,
      panelTitle: 'General Settings',
      panelSubtitle: 'Common board configuration shared across all targets',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.info_outline,
          title: 'System Info',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.badge, 'Hostname', 'hostname'),
              btn(Icons.memory, 'Model', 'cat /proc/device-tree/model'),
              btn(Icons.terminal, 'Kernel', 'uname -a'),
              btn(Icons.schedule, 'Uptime', 'uptime -p'),
              btn(Icons.info, 'OS Release', 'cat /etc/os-release'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.language,
          title: 'Locale & Environment',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.translate, 'Locale', 'locale'),
              btn(Icons.list, 'Environment', 'env'),
              btn(Icons.person, 'Whoami', 'whoami'),
              btn(Icons.terminal, 'Shell', 'echo \$SHELL'),
            ],
          ),
        ),
      ],
    );
  }
}
