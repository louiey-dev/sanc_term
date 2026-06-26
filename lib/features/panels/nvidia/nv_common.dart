import 'package:flutter/material.dart';
import 'package:sanc_term/core/utils/snackbars.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Shared action buttons shown at the top-right of every NVIDIA panel.
///
/// Drop this into a panel header's `panelActions` so all NVIDIA panels expose
/// the same board-wide controls (SSH session, refresh, help). Wire the
/// callbacks to real behaviour as features land — they snackbar for now.
class NvCommonActions extends StatelessWidget {
  const NvCommonActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelActionButton(
          icon: Icons.info_outline,
          label: 'version',
          tooltipStr: 'Get OS related version info',
          onPressed: () => showSnackbar(context, 'VER: not implemented'),
        ),
        const SizedBox(width: 8),
        PanelActionButton(
          icon: Icons.memory,
          label: 'dts model',
          tooltipStr: 'Read dts model info',
          onPressed: () =>
              showSnackbar(context, 'DTS info read: not implemented'),
        ),
        const SizedBox(width: 8),
        PanelActionButton(
          icon: Icons.terminal_outlined,
          label: 'nvidia-smi',
          tooltipStr: 'NVIDIA System Management Interface',
          onPressed: () => showSnackbar(context, 'nvidia-smi: not implemented'),
        ),
      ],
    );
  }
}
