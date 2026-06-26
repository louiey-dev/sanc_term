import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

export 'package:sanc_term/features/panels/common/board_command.dart'
    show sendBoardCommand;

/// Shared action buttons shown at the top-right of every NVIDIA panel.
class NvCommonActions extends ConsumerWidget {
  const NvCommonActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelActionButton(
          icon: Icons.info_outline,
          label: 'version',
          tooltipStr: 'Get OS / kernel version info',
          onPressed: () => sendBoardCommand(
            ref,
            context,
            'cat /proc/version; cat /etc/os-release',
          ),
        ),
        const SizedBox(width: 8),
        PanelActionButton(
          icon: Icons.memory,
          label: 'dts model',
          tooltipStr: 'Read device-tree model',
          onPressed: () =>
              sendBoardCommand(ref, context, 'cat /proc/device-tree/model'),
        ),
        const SizedBox(width: 8),
        PanelActionButton(
          icon: Icons.terminal_outlined,
          label: 'nvidia-smi',
          tooltipStr: 'NVIDIA System Management Interface',
          onPressed: () => sendBoardCommand(ref, context, 'nvidia-smi'),
        ),
      ],
    );
  }
}
