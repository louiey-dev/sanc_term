import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvAudioPanel extends ConsumerWidget {
  const NvAudioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.audiotrack,
      panelTitle: 'nVidia Audio',
      panelSubtitle: 'Audio configuration and base info',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.audiotrack,
          title: 'Audio Devices',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'List ALSA playback / capture devices and sound cards.',
                style: TextStyle(fontSize: 12, color: c.foreground),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: Icons.speaker,
                    label: 'Playback',
                    tooltipStr: 'aplay -l',
                    onPressed: () => sendBoardCommand(ref, context, 'aplay -l'),
                  ),
                  PanelActionButton(
                    icon: Icons.mic,
                    label: 'Capture',
                    tooltipStr: 'arecord -l',
                    onPressed: () =>
                        sendBoardCommand(ref, context, 'arecord -l'),
                  ),
                  PanelActionButton(
                    icon: Icons.list,
                    label: 'Cards',
                    tooltipStr: 'cat /proc/asound/cards',
                    onPressed: () =>
                        sendBoardCommand(ref, context, 'cat /proc/asound/cards'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
