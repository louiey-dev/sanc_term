import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvHdmiPanel extends ConsumerStatefulWidget {
  const NvHdmiPanel({super.key});

  @override
  ConsumerState<NvHdmiPanel> createState() => _NvHdmiPanelState();
}

class _NvHdmiPanelState extends ConsumerState<NvHdmiPanel> {
  final _grep = TextEditingController(text: 'Samsung');
  final _width = TextEditingController(text: '1920');
  final _height = TextEditingController(text: '1080');
  final _hz = TextEditingController(text: '60');
  final _hdmiNum = TextEditingController(text: '0');

  static const _xauth = 'XAUTHORITY=/run/user/128/gdm/Xauthority DISPLAY=:0';

  @override
  void dispose() {
    _grep.dispose();
    _width.dispose();
    _height.dispose();
    _hz.dispose();
    _hdmiNum.dispose();
    super.dispose();
  }

  PanelActionButton _cmd(String label, String command, {String? tip}) =>
      PanelActionButton(
        icon: Icons.read_more_outlined,
        label: label,
        tooltipStr: tip ?? command,
        onPressed: () => sendBoardCommand(ref, context, command),
      );

  Widget _field(TextEditingController c, String label, double width) => SizedBox(
        width: width,
        height: 40,
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.tv,
      panelTitle: 'nVidia HDMI',
      panelSubtitle: 'HDMI configuration and base info',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.monitor,
          title: 'HDMI Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_grep, 'Grep keyword', 180),
                  _cmd(
                    'Xorg log',
                    'grep -i ${_grep.text} /var/log/Xorg.0.log; tail -n 100 /var/log/Xorg.0.log',
                    tip: 'grep + tail Xorg.0.log',
                  ),
                  _cmd('Xrandr', 'sudo $_xauth xrandr', tip: 'xrandr'),
                  _cmd('DRM connectors', 'ls -al /sys/class/drm'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _cmd('Status', 'cat /sys/class/drm/card1-HDMI-A-1/status'),
                  _cmd('Enabled', 'cat /sys/class/drm/card1-HDMI-A-1/enabled'),
                  _cmd('Modes', 'cat /sys/class/drm/card1-HDMI-A-1/modes'),
                  _cmd('Framebuffer', 'cat /proc/fb'),
                  _cmd(
                    'Display Server',
                    'ps aux | grep -E "Xorg|weston|gnome-shell" | grep -v grep',
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.settings_outlined,
          title: 'HDMI Control',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Set 1080p@60',
                    tooltipStr: 'xrandr 1920x1080@60',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo $_xauth xrandr --output HDMI-${_hdmiNum.text} --mode 1920x1080 --rate 60',
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Set 4K@30',
                    tooltipStr: 'xrandr 3840x2160@30',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo $_xauth xrandr --output HDMI-${_hdmiNum.text} --mode 3840x2160 --rate 30',
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Turn Off',
                    tooltipStr: 'xrandr --off',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo $_xauth xrandr --output HDMI-${_hdmiNum.text} --off',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_width, 'Width', 80),
                  _field(_height, 'Height', 80),
                  _field(_hz, 'Rate', 80),
                  _field(_hdmiNum, 'HDMI #', 80),
                  PanelActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Apply Custom',
                    tooltipStr: 'xrandr custom mode',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'sudo $_xauth xrandr --output HDMI-${_hdmiNum.text} --mode ${_width.text}x${_height.text} --rate ${_hz.text}',
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
}
