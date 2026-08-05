import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// CUSTOMS — Fire Camera & Thermal Monitoring Panel (rv1106_firecam)
class FireCamPanel extends ConsumerStatefulWidget {
  final bool standalone;

  const FireCamPanel({super.key, this.standalone = true});

  @override
  ConsumerState<FireCamPanel> createState() => _FireCamPanelState();
}

/// State model for preserving FireCam panel parameters across page transitions
class FireCamParamsState {
  final String tempThreshold;
  final String customCmd;
  final String lineoutVolume;
  final String smokeThreshold;

  const FireCamParamsState({
    this.tempThreshold = '75.0',
    this.customCmd = 'status',
    this.lineoutVolume = '80',
    this.smokeThreshold = '300',
  });
}

/// Riverpod provider for persisting FireCam panel parameter values
final fireCamParamsProvider = StateProvider<FireCamParamsState>(
  (ref) => const FireCamParamsState(),
);

class _FireCamPanelState extends ConsumerState<FireCamPanel> {
  late final TextEditingController _tempThreshold;
  late final TextEditingController _customCmd;
  late final TextEditingController _lineoutVolumeCtrl;
  late final TextEditingController _smokeThresholdCtrl;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(fireCamParamsProvider);
    _tempThreshold = TextEditingController(text: saved.tempThreshold);
    _customCmd = TextEditingController(text: saved.customCmd);
    _lineoutVolumeCtrl = TextEditingController(text: saved.lineoutVolume);
    _smokeThresholdCtrl = TextEditingController(text: saved.smokeThreshold);

    _tempThreshold.addListener(_saveParams);
    _customCmd.addListener(_saveParams);
    _lineoutVolumeCtrl.addListener(_saveParams);
    _smokeThresholdCtrl.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(fireCamParamsProvider.notifier).state = FireCamParamsState(
      tempThreshold: _tempThreshold.text,
      customCmd: _customCmd.text,
      lineoutVolume: _lineoutVolumeCtrl.text,
      smokeThreshold: _smokeThresholdCtrl.text,
    );
  }

  @override
  void dispose() {
    _tempThreshold.dispose();
    _customCmd.dispose();
    _lineoutVolumeCtrl.dispose();
    _smokeThresholdCtrl.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.local_fire_department,
    label: label,
    tooltipStr: tip,
    onPressed: () => _send(cmd),
  );

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double width = 130,
    String? hint,
  }) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: SelectableText(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bodies = _buildPanelBodies();
    if (widget.standalone) {
      return MyPanel(
        icon: Icons.local_fire_department,
        panelTitle: 'Fire Cam Panel',
        panelSubtitle:
            'rv1106_firecam custom board controls, dual RGB LEDs, memory & sensors',
        panelActions: const [],
        children: bodies,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < bodies.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          bodies[i],
        ],
      ],
    );
  }

  List<Widget> _buildPanelBodies() {
    return [
      MyPanelBody(
        icon: Icons.light_mode,
        title: 'CUSTOMS — Dual RGB LED Control (Action & Status)',
        subtitle:
            'Independent Action RGB LED and Status RGB LED color & pattern controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Action RGB LED Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Red ON',
                  'echo 1 > /sys/class/leds/action:red/brightness',
                  'Turn Action Red LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Red OFF',
                  'echo 0 > /sys/class/leds/action:red/brightness',
                  'Turn Action Red LED OFF',
                  Icons.circle_outlined,
                ),
                _btn(
                  'Green ON',
                  'echo 1 > /sys/class/leds/action:green/brightness',
                  'Turn Action Green LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Green OFF',
                  'echo 0 > /sys/class/leds/action:green/brightness',
                  'Turn Action Green LED OFF',
                  Icons.circle_outlined,
                ),
                _btn(
                  'Blue ON',
                  'echo 1 > /sys/class/leds/action:blue/brightness',
                  'Turn Action Blue LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Blue OFF',
                  'echo 0 > /sys/class/leds/action:blue/brightness',
                  'Turn Action Blue LED OFF',
                  Icons.circle_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Status RGB LED Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Red ON',
                  'echo 1 > /sys/class/leds/status:red/brightness',
                  'Turn Status Red LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Red OFF',
                  'echo 0 > /sys/class/leds/status:red/brightness',
                  'Turn Status Red LED OFF',
                  Icons.circle_outlined,
                ),
                _btn(
                  'Green ON',
                  'echo 1 > /sys/class/leds/status:green/brightness',
                  'Turn Status Green LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Green OFF',
                  'echo 0 > /sys/class/leds/status:green/brightness',
                  'Turn Status Green LED OFF',
                  Icons.circle_outlined,
                ),
                _btn(
                  'Blue ON',
                  'echo 1 > /sys/class/leds/status:blue/brightness',
                  'Turn Status Blue LED ON',
                  Icons.circle,
                ),
                _btn(
                  'Blue OFF',
                  'echo 0 > /sys/class/leds/status:blue/brightness',
                  'Turn Status Blue LED OFF',
                  Icons.circle_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.sd_storage,
        title: 'CUSTOMS — Memory & Storage Subsystems',
        subtitle:
            'DDR SDRAM, eMMC flash & SD Card status, bandwidth & health utilities',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('DDR SDRAM Memory'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Read Capacity',
                  'rv1106_firecam ddr info',
                  'Show DDR SDRAM capacity & memory usage',
                  Icons.memory,
                ),
                _btn(
                  'Bandwidth Benchmark',
                  'rv1106_firecam ddr speed',
                  'Run DDR SDRAM read/write bandwidth benchmark',
                  Icons.speed,
                ),
                _btn(
                  'Stress Benchmark',
                  'rv1106_firecam ddr stress',
                  'Run DDR SDRAM pattern stress benchmark',
                  Icons.assessment,
                ),
                _btn(
                  'Flush Cache',
                  'rv1106_firecam ddr drop_caches',
                  'Flush pagecache, dentries & inodes',
                  Icons.cleaning_services,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('eMMC Flash Storage'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Partition Info',
                  'rv1106_firecam emmc info',
                  'Show eMMC partition usage & filesystem mount status',
                  Icons.storage,
                ),
                _btn(
                  'Read Benchmark',
                  'rv1106_firecam emmc read_speed',
                  'Measure eMMC sequential read speed',
                  Icons.download,
                ),
                _btn(
                  'Write Benchmark',
                  'rv1106_firecam emmc write_speed',
                  'Measure eMMC sequential write speed',
                  Icons.upload,
                ),
                _btn(
                  'ExtCSD Health',
                  'rv1106_firecam emmc health',
                  'Read eMMC ExtCSD health & wear-level status',
                  Icons.health_and_safety,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('SD Card Interface'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Detect Card',
                  'rv1106_firecam sdcard status',
                  'Detect SD card insertion & card detect pin state',
                  Icons.sd_card,
                ),
                _btn(
                  'Mount Filesystem',
                  'rv1106_firecam sdcard mount',
                  'Mount SD card partition to /mnt/sdcard',
                  Icons.folder_zip,
                ),
                _btn(
                  'Unmount Card',
                  'rv1106_firecam sdcard umount',
                  'Safely unmount SD card partition',
                  Icons.eject,
                ),
                _btn(
                  'Speed Benchmark',
                  'rv1106_firecam sdcard benchmark',
                  'Measure SD card read/write transfer speed',
                  Icons.speed,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.lan,
        title: 'CUSTOMS — Ethernet & Wireless Interfaces',
        subtitle:
            'Ethernet MAC/PHY, Wi-Fi 802.11 & Bluetooth LE interface controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Ethernet Network Interface'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Link & IP Info',
                  'rv1106_firecam eth info',
                  'Display Ethernet IP address, MAC & link status',
                  Icons.lan,
                ),
                _btn(
                  'Ping Gateway',
                  'rv1106_firecam eth ping_gw',
                  'Ping default network gateway router',
                  Icons.network_check,
                ),
                _btn(
                  'PHY Duplex / Speed',
                  'rv1106_firecam eth phy',
                  'Read Ethernet PHY autonegotiation speed & duplex mode',
                  Icons.settings_ethernet,
                ),
                _btn(
                  'DHCP Renew',
                  'rv1106_firecam eth dhcp',
                  'Renew DHCP lease for Ethernet interface',
                  Icons.sync,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Wi-Fi 802.11 Interface'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Connection Status',
                  'rv1106_firecam wifi info',
                  'Display Wi-Fi connection state, SSID & RSSI signal',
                  Icons.wifi,
                ),
                _btn(
                  'Scan AP List',
                  'rv1106_firecam wifi scan',
                  'Scan surrounding Wi-Fi access points',
                  Icons.wifi_find,
                ),
                _btn(
                  'Ping Gateway',
                  'rv1106_firecam wifi ping',
                  'Ping gateway through Wi-Fi interface',
                  Icons.network_ping,
                ),
                _btn(
                  'Disconnect AP',
                  'rv1106_firecam wifi disconnect',
                  'Disconnect from current Wi-Fi network',
                  Icons.wifi_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Bluetooth LE Interface'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Controller Status',
                  'rv1106_firecam bt info',
                  'Display Bluetooth HCI controller MAC & state',
                  Icons.bluetooth,
                ),
                _btn(
                  'Scan LE Devices',
                  'rv1106_firecam bt scan',
                  'Scan nearby Bluetooth Low Energy devices',
                  Icons.bluetooth_searching,
                ),
                _btn(
                  'Start Advertising',
                  'rv1106_firecam bt adv_start',
                  'Start BLE beacon advertising mode',
                  Icons.bluetooth_drive,
                ),
                _btn(
                  'Stop Advertising',
                  'rv1106_firecam bt adv_stop',
                  'Stop BLE beacon advertising mode',
                  Icons.bluetooth_disabled,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.mic,
        title: 'CUSTOMS — Audio & Environmental Sensors',
        subtitle:
            'Microphone capture, Audio Line-out speaker & Smoke Sensor safety monitoring',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Microphone Input Capture'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Codec Status',
                  'rv1106_firecam mic info',
                  'Show MIC hardware codec gain & sample rate',
                  Icons.mic,
                ),
                _btn(
                  'Start 3s Capture',
                  'rv1106_firecam mic rec_start',
                  'Record 3-second WAV sample from MIC input',
                  Icons.keyboard_voice,
                ),
                _btn(
                  'Stop Capture',
                  'rv1106_firecam mic rec_stop',
                  'Stop ongoing microphone audio capture',
                  Icons.mic_off,
                ),
                _btn(
                  'Read Sound Level',
                  'rv1106_firecam mic db_level',
                  'Read current ambient sound level in dB',
                  Icons.graphic_eq,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Audio Line-Out & Speaker'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Codec Status',
                  'rv1106_firecam lineout info',
                  'Show audio line-out codec status & volume level',
                  Icons.volume_up,
                ),
                _btn(
                  'Play 1kHz Sine',
                  'rv1106_firecam lineout play_sine',
                  'Play 1kHz test sine tone through Line-out',
                  Icons.music_note,
                ),
                _btn(
                  'Play Alarm Siren',
                  'rv1106_firecam lineout play_siren',
                  'Play fire alarm siren audio pattern',
                  Icons.campaign,
                ),
                _btn(
                  'Mute Output',
                  'rv1106_firecam lineout mute',
                  'Mute Line-out speaker channel',
                  Icons.volume_off,
                ),
                _btn(
                  'Unmute Output',
                  'rv1106_firecam lineout unmute',
                  'Unmute Line-out speaker channel',
                  Icons.volume_up,
                ),
                _inputField(
                  _lineoutVolumeCtrl,
                  'Vol (0..100)',
                  width: 130,
                  hint: '80',
                ),
                PanelActionButton(
                  icon: Icons.volume_mute,
                  label: 'Set Volume',
                  tooltipStr: 'rv1106_firecam lineout volume <0..100>',
                  onPressed: () {
                    final val = _lineoutVolumeCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send('rv1106_firecam lineout volume $val');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Smoke Sensor & Environmental Safety'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Read ADC Voltage',
                  'rv1106_firecam smoke adc',
                  'Read raw smoke sensor ADC voltage input',
                  Icons.electric_meter,
                ),
                _btn(
                  'Sensor Status',
                  'rv1106_firecam smoke status',
                  'Read smoke sensor concentration & alarm state',
                  Icons.sensor_door,
                ),
                _btn(
                  'Trigger Buzzer',
                  'rv1106_firecam smoke buzzer',
                  'Trigger smoke alarm buzzer hardware alert',
                  Icons.notification_important,
                ),
                _btn(
                  'Calibrate Zero',
                  'rv1106_firecam smoke calib',
                  'Calibrate smoke sensor zero-point baseline',
                  Icons.tune,
                ),
                _inputField(
                  _smokeThresholdCtrl,
                  'Smoke Limit',
                  width: 140,
                  hint: '300',
                ),
                PanelActionButton(
                  icon: Icons.shield,
                  label: 'Set Limit',
                  tooltipStr: 'rv1106_firecam smoke threshold <value>',
                  onPressed: () {
                    final val = _smokeThresholdCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send('rv1106_firecam smoke threshold $val');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.psychology,
        title: 'CUSTOMS — rv1106_firecam Subsystem & AI Menu',
        subtitle: 'NPU inference engine, RTSP streaming & board power controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('NPU & RTSP Video Streaming'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'NPU Load',
                  'rv1106_firecam npu load',
                  'Show NPU utilization load',
                  Icons.query_stats,
                ),
                _btn(
                  'AI Start',
                  'rv1106_firecam npu detect start',
                  'Start AI object & fire detection loop',
                  Icons.play_arrow,
                ),
                _btn(
                  'AI Stop',
                  'rv1106_firecam npu detect stop',
                  'Stop AI object & fire detection loop',
                  Icons.stop,
                ),
                _btn(
                  'RTSP Start',
                  'rv1106_firecam rtsp start',
                  'Start RTSP live video server',
                  Icons.live_tv,
                ),
                _btn(
                  'RTSP Stop',
                  'rv1106_firecam rtsp stop',
                  'Stop RTSP live video server',
                  Icons.portable_wifi_off,
                ),
                _btn(
                  'Reset Board',
                  'rv1106_firecam reset',
                  'Reset rv1106_firecam board hardware',
                  Icons.refresh,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.local_fire_department,
        title: 'CUSTOMS — Fire Camera Control (rv1106_firecam)',
        subtitle:
            'Thermal imaging, fire detection threshold & rv1106_firecam board controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('rv1106_firecam Board & Camera Stream Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Status',
                  'rv1106_firecam status',
                  'Show rv1106_firecam status',
                  Icons.info_outline,
                ),
                _btn(
                  'Stream Start',
                  'rv1106_firecam stream start',
                  'Start thermal video stream',
                  Icons.videocam,
                ),
                _btn(
                  'Stream Stop',
                  'rv1106_firecam stream stop',
                  'Stop thermal video stream',
                  Icons.videocam_off,
                ),
                _btn(
                  'Calibrate Zero',
                  'rv1106_firecam calibrate',
                  'Calibrate thermal sensor zero-point',
                  Icons.tune,
                ),
                _btn(
                  'Trigger Alarm',
                  'rv1106_firecam alarm trigger',
                  'Trigger fire detection alarm action',
                  Icons.warning_amber,
                ),
                _btn(
                  'IRCUT ON',
                  'rv1106_firecam ircut 1',
                  'Enable IR-Cut filter (Day Mode)',
                  Icons.wb_sunny,
                ),
                _btn(
                  'IRCUT OFF',
                  'rv1106_firecam ircut 0',
                  'Disable IR-Cut filter (Night Mode)',
                  Icons.nights_stay,
                ),
                _btn(
                  'ISP Start',
                  'rv1106_firecam isp start',
                  'Start ISP video stream pipeline',
                  Icons.camera_alt,
                ),
                _btn(
                  'ISP Stop',
                  'rv1106_firecam isp stop',
                  'Stop ISP video stream pipeline',
                  Icons.camera,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Temperature Threshold Config'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tempThreshold,
                  'Max Temp (°C)',
                  width: 140,
                  hint: '75.0',
                ),
                PanelActionButton(
                  icon: Icons.thermostat,
                  label: 'Set Threshold',
                  tooltipStr: 'rv1106_firecam temp_threshold <value>',
                  onPressed: () {
                    final val = _tempThreshold.text.trim();
                    if (val.isNotEmpty) {
                      _send('rv1106_firecam temp_threshold $val');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Custom rv1106_firecam Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_customCmd, 'Command', width: 240, hint: 'status'),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send Cmd',
                  tooltipStr: 'Send raw rv1106_firecam command',
                  onPressed: () {
                    final cmd = _customCmd.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(
                        cmd.startsWith('rv1106_firecam ')
                            ? cmd
                            : 'rv1106_firecam $cmd',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}
