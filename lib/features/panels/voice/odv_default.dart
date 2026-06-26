import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/features/panels/voice/tts_app.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// On-device voice demo controls (Rockchip RK3506). The reference's TTS feature
/// is omitted (separate subsystem); this covers the command controls.
class OnDeviceVoicePanel extends ConsumerWidget {
  const OnDeviceVoicePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    PanelActionButton btn(
      IconData i,
      String label,
      String cmd, {
      String? tip,
    }) => PanelActionButton(
      icon: i,
      label: label,
      tooltipStr: tip ?? cmd,
      onPressed: () => sendBoardCommand(ref, context, cmd),
    );
    return MyPanel(
      icon: Icons.record_voice_over,
      panelTitle: 'On-Device Voice',
      panelSubtitle: 'Voice demo settings and controls',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.terminal,
          title: 'Shell / Info',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.terminal_outlined, 'shell', 'adb shell'),
              btn(Icons.segment_outlined, 'aliases', "alias ll='ls -al'"),
              btn(
                Icons.info_outline,
                'version',
                'uname -a; lsb_release -a; cat /etc/os-release',
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.voice_chat,
          title: 'Voice Demo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'voice_demo: .../buildroot/output/rockchip_rk3506_tiny/build/voice_demo\n'
                'update img: .../output/firmware/update.img',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  color: c.muted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  btn(
                    Icons.voice_chat,
                    'voice_demo',
                    '/userdata/voice_demo -i /userdata/voice_demo_magic_water_purifier.ini',
                  ),
                  btn(
                    Icons.voice_chat,
                    'tnt_onvoice',
                    '/userdata/tnt_onvoice -i /userdata/voice_demo_magic_water_purifier.ini',
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.tune,
          title: 'Control',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.change_circle_outlined, 'Slot 0', 'slot 0'),
              btn(Icons.change_circle_outlined, 'Slot 1', 'slot 1'),
              btn(Icons.mic, 'MIC On', 'mute 1'),
              btn(Icons.mic_off, 'MIC Off', 'mute 0'),
              btn(Icons.record_voice_over, 'REC On', 'rec 1'),
              btn(Icons.voice_over_off, 'REC Off', 'rec 0'),
              TtsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
