import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// STM32F746G-DISCO Evaluation Board Panel.
/// Provides sub panels for General, Audio, Storage, Ethernet, and LCD.
class F746DiscoPanel extends ConsumerStatefulWidget {
  const F746DiscoPanel({super.key});

  @override
  ConsumerState<F746DiscoPanel> createState() => _F746DiscoPanelState();
}

class _F746DiscoPanelState extends ConsumerState<F746DiscoPanel> {
  String _selectedTab = 'all';

  // General Controllers
  final _sdramReadAddr = TextEditingController(text: '0x00000000');
  final _sdramReadSize = TextEditingController(text: '32');
  final _sdramWriteAddr = TextEditingController(text: '0x00000000');
  final _sdramWriteVal = TextEditingController(text: '0x55AA55AA');
  final _sdramWriteSize = TextEditingController(text: '1024');

  // Audio Controllers
  final _audioVol = TextEditingController(text: '70');

  // Storage Controllers
  final _qspiReadAddr = TextEditingController(text: '0x90000000');
  final _qspiReadSize = TextEditingController(text: '256');
  final _qspiWriteAddr = TextEditingController(text: '0x90000000');
  final _qspiWriteVal = TextEditingController(text: '0xFF');
  final _qspiWriteSize = TextEditingController(text: '256');
  bool _qspiWriteAutoErase = false;
  final _qspiEraseAddr = TextEditingController(text: '0x90000000');
  final _qspiEraseSize = TextEditingController(text: '4096');

  final _sdLsPath = TextEditingController(text: '/SD:');
  final _sdCatPath = TextEditingController(text: '/SD:/test.txt');
  final _sdReadPath = TextEditingController(text: '/SD:/test.txt');
  final _sdReadLen = TextEditingController(text: '512');
  final _sdWritePath = TextEditingController(text: '/SD:/test.txt');
  final _sdWriteContent = TextEditingController(text: 'Hello SD Card');
  final _sdAppendPath = TextEditingController(text: '/SD:/test.txt');
  final _sdAppendContent = TextEditingController(text: 'Appended line');
  final _sdRmPath = TextEditingController(text: '/SD:/test.txt');
  final _sdMkdirPath = TextEditingController(text: '/SD:/newdir');

  // Ethernet Controllers
  final _ethIp = TextEditingController(text: '192.168.1.100');
  final _ethNetmask = TextEditingController(text: '255.255.255.0');
  final _ethGw = TextEditingController(text: '192.168.1.1');
  final _ethPingTarget = TextEditingController(text: '192.168.1.1');

  final _ethUdpHost = TextEditingController(text: '192.168.1.1');
  final _ethUdpPort = TextEditingController(text: '5000');
  final _ethUdpData = TextEditingController(text: 'Hello UDP');
  final _ethUdpRecvPort = TextEditingController(text: '5000');

  final _ethTcpHost = TextEditingController(text: '192.168.1.1');
  final _ethTcpPort = TextEditingController(text: '8000');
  final _ethTcpData = TextEditingController(text: 'Hello TCP');
  final _ethTcpRecvPort = TextEditingController(text: '8000');

  // LCD Controllers
  final _lcdClearColor = TextEditingController(text: '0x0000');
  final _lcdTouchDrawColor = TextEditingController(text: '0xF800');
  final _lcdBoxX = TextEditingController(text: '10');
  final _lcdBoxY = TextEditingController(text: '10');
  final _lcdBoxW = TextEditingController(text: '100');
  final _lcdBoxH = TextEditingController(text: '100');
  final _lcdBoxColor = TextEditingController(text: '0xFFFF');

  final _lcdFillRectX = TextEditingController(text: '120');
  final _lcdFillRectY = TextEditingController(text: '10');
  final _lcdFillRectW = TextEditingController(text: '100');
  final _lcdFillRectH = TextEditingController(text: '100');
  final _lcdFillRectColor = TextEditingController(text: '0xF800');

  final _lcdCircleX = TextEditingController(text: '60');
  final _lcdCircleY = TextEditingController(text: '180');
  final _lcdCircleR = TextEditingController(text: '40');
  final _lcdCircleColor = TextEditingController(text: '0x07E0');

  final _lcdFillCircleX = TextEditingController(text: '170');
  final _lcdFillCircleY = TextEditingController(text: '180');
  final _lcdFillCircleR = TextEditingController(text: '40');
  final _lcdFillCircleColor = TextEditingController(text: '0x001F');

  final _lcdLineX1 = TextEditingController(text: '10');
  final _lcdLineY1 = TextEditingController(text: '240');
  final _lcdLineX2 = TextEditingController(text: '220');
  final _lcdLineY2 = TextEditingController(text: '240');
  final _lcdLineColor = TextEditingController(text: '0xFFFF');

  final _lcdPrintX = TextEditingController(text: '10');
  final _lcdPrintY = TextEditingController(text: '255');
  String _lcdPrintFontSize = 'medium';
  final _lcdPrintStr = TextEditingController(text: 'Hello STM32!');
  final _lcdPrintFgColor = TextEditingController(text: '0xFFFF');
  final _lcdPrintBgColor = TextEditingController(text: '');

  @override
  void dispose() {
    _sdramReadAddr.dispose();
    _sdramReadSize.dispose();
    _sdramWriteAddr.dispose();
    _sdramWriteVal.dispose();
    _sdramWriteSize.dispose();

    _audioVol.dispose();

    _qspiReadAddr.dispose();
    _qspiReadSize.dispose();
    _qspiWriteAddr.dispose();
    _qspiWriteVal.dispose();
    _qspiWriteSize.dispose();
    _qspiEraseAddr.dispose();
    _qspiEraseSize.dispose();

    _sdLsPath.dispose();
    _sdCatPath.dispose();
    _sdReadPath.dispose();
    _sdReadLen.dispose();
    _sdWritePath.dispose();
    _sdWriteContent.dispose();
    _sdAppendPath.dispose();
    _sdAppendContent.dispose();
    _sdRmPath.dispose();
    _sdMkdirPath.dispose();

    _ethIp.dispose();
    _ethNetmask.dispose();
    _ethGw.dispose();
    _ethPingTarget.dispose();

    _ethUdpHost.dispose();
    _ethUdpPort.dispose();
    _ethUdpData.dispose();
    _ethUdpRecvPort.dispose();

    _ethTcpHost.dispose();
    _ethTcpPort.dispose();
    _ethTcpData.dispose();
    _ethTcpRecvPort.dispose();

    _lcdClearColor.dispose();
    _lcdTouchDrawColor.dispose();
    _lcdBoxX.dispose();
    _lcdBoxY.dispose();
    _lcdBoxW.dispose();
    _lcdBoxH.dispose();
    _lcdBoxColor.dispose();

    _lcdFillRectX.dispose();
    _lcdFillRectY.dispose();
    _lcdFillRectW.dispose();
    _lcdFillRectH.dispose();
    _lcdFillRectColor.dispose();

    _lcdCircleX.dispose();
    _lcdCircleY.dispose();
    _lcdCircleR.dispose();
    _lcdCircleColor.dispose();

    _lcdFillCircleX.dispose();
    _lcdFillCircleY.dispose();
    _lcdFillCircleR.dispose();
    _lcdFillCircleColor.dispose();

    _lcdLineX1.dispose();
    _lcdLineY1.dispose();
    _lcdLineX2.dispose();
    _lcdLineY2.dispose();
    _lcdLineColor.dispose();

    _lcdPrintX.dispose();
    _lcdPrintY.dispose();
    _lcdPrintStr.dispose();
    _lcdPrintFgColor.dispose();
    _lcdPrintBgColor.dispose();

    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.bolt,
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
    child: Text(
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
    return MyPanel(
      icon: Icons.memory,
      panelTitle: 'F746-DISCO Panel',
      panelSubtitle:
          'STM32F746G-DISCO peripherals, audio, storage, network & LCD controls',
      panelActions: const [],
      children: [
        // Sub panel Selector Bar
        MyPanelBody(
          icon: Icons.category,
          title: 'Sub Panels',
          subtitle: 'Select sub panel view',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tabButton('All', 'all', Icons.grid_view),
              _tabButton('General', 'general', Icons.tune),
              _tabButton('Audio', 'audio', Icons.audiotrack),
              _tabButton('Storage', 'storage', Icons.storage),
              _tabButton('Ethernet', 'ethernet', Icons.lan),
              _tabButton('LCD', 'lcd', Icons.desktop_windows),
            ],
          ),
        ),

        if (_selectedTab == 'all' || _selectedTab == 'general')
          ..._buildGeneralSubpanel(),
        if (_selectedTab == 'all' || _selectedTab == 'audio')
          ..._buildAudioSubpanel(),
        if (_selectedTab == 'all' || _selectedTab == 'storage')
          ..._buildStorageSubpanel(),
        if (_selectedTab == 'all' || _selectedTab == 'ethernet')
          ..._buildEthernetSubpanel(),
        if (_selectedTab == 'all' || _selectedTab == 'lcd')
          ..._buildLcdSubpanel(),
      ],
    );
  }

  Widget _tabButton(String label, String tabKey, IconData icon) {
    final isSelected = _selectedTab == tabKey;
    final c = context.colors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: isSelected ? c.primary : c.border),
        backgroundColor: isSelected
            ? c.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        foregroundColor: isSelected ? c.primary : c.foreground,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label),
      onPressed: () => setState(() => _selectedTab = tabKey),
    );
  }

  // ===========================================================================
  // 1. GENERAL SUB PANEL
  // ===========================================================================
  List<Widget> _buildGeneralSubpanel() {
    return [
      MyPanelBody(
        icon: Icons.tune,
        title: 'General — LED & Button',
        subtitle: 'LED on/off/toggle and user push button status check',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('LED Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('LED On', 'led on', 'Turn on board LED', Icons.light_mode),
                _btn(
                  'LED Off',
                  'led off',
                  'Turn off board LED',
                  Icons.dark_mode,
                ),
                _btn(
                  'LED Toggle',
                  'led toggle',
                  'Toggle board LED state',
                  Icons.swap_horiz,
                ),
                _btn(
                  'LED Status',
                  'led status',
                  'Query LED status',
                  Icons.info_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('User Button'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Button Status',
                  'button status',
                  'Read user push button status',
                  Icons.smart_button,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.sd_storage,
        title: 'General — SDRAM Test',
        subtitle:
            'Check SDRAM status, read/write specified address with size, and run memory test',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Check Status',
                  'sdram status',
                  'Check SDRAM configuration and status',
                  Icons.info_outline,
                ),
                _btn(
                  'SDRAM Test',
                  'sdram test',
                  'Run full SDRAM test',
                  Icons.play_arrow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('SDRAM Read 0xC0000000'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _sdramReadAddr,
                  'Offset',
                  width: 140,
                  hint: '0xC0000000',
                ),
                _inputField(_sdramReadSize, 'Size', width: 100, hint: '1024'),
                PanelActionButton(
                  icon: Icons.upload,
                  label: 'Read',
                  tooltipStr: 'sdram read <addr> <size>',
                  onPressed: () {
                    final addr = _sdramReadAddr.text.trim();
                    final size = _sdramReadSize.text.trim();
                    if (addr.isNotEmpty && size.isNotEmpty) {
                      _send('sdram read $addr $size');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('SDRAM Write 0xC0000000'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _sdramWriteAddr,
                  'Offset',
                  width: 140,
                  hint: '0xC0000000',
                ),
                _inputField(
                  _sdramWriteVal,
                  'Value/Pattern',
                  width: 130,
                  hint: '0x55AA55AA',
                ),
                PanelActionButton(
                  icon: Icons.download,
                  label: 'Write',
                  tooltipStr: 'sdram write <addr> <val>',
                  onPressed: () {
                    final addr = _sdramWriteAddr.text.trim();
                    final val = _sdramWriteVal.text.trim();
                    if (addr.isNotEmpty && val.isNotEmpty) {
                      _send('sdram write $addr $val');
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

  // ===========================================================================
  // 2. AUDIO SUB PANEL
  // ===========================================================================
  List<Widget> _buildAudioSubpanel() {
    return [
      MyPanelBody(
        icon: Icons.audiotrack,
        title: 'Audio',
        subtitle:
            'Play / Pause / Resume / Stop, volume control, status & audio test',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Playback Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Play',
                  'audio play',
                  'Start audio playback',
                  Icons.play_arrow,
                ),
                _btn(
                  'Pause',
                  'audio pause',
                  'Pause audio playback',
                  Icons.pause,
                ),
                _btn(
                  'Resume',
                  'audio resume',
                  'Resume audio playback',
                  Icons.play_arrow_outlined,
                ),
                _btn('Stop', 'audio stop', 'Stop audio playback', Icons.stop),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Volume Control & Status'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_audioVol, 'Volume (0-100)', width: 120),
                PanelActionButton(
                  icon: Icons.tune,
                  label: 'Set VOL',
                  tooltipStr: 'audio volume <level>',
                  onPressed: () {
                    final vol = _audioVol.text.trim();
                    if (vol.isNotEmpty) _send('audio volume $vol');
                  },
                ),
                _btn(
                  'Check Status',
                  'audio status',
                  'Check audio subsystem status',
                  Icons.info_outline,
                ),
                _btn(
                  'Audio Test',
                  'audio test',
                  'Run audio diagnostic test',
                  Icons.science,
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ===========================================================================
  // 3. STORAGE SUB PANEL
  // ===========================================================================
  List<Widget> _buildStorageSubpanel() {
    return [
      MyPanelBody(
        icon: Icons.memory,
        title: 'Storage — QSPI Flash',
        subtitle:
            'QSPI flash status, read/write given address/value/size, and test',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Check Status',
                  'qspi status',
                  'Check QSPI flash status',
                  Icons.info_outline,
                ),
                _btn(
                  'QSPI Test',
                  'qspi test',
                  'Run QSPI read/write test',
                  Icons.science,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('QSPI Read'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _qspiReadAddr,
                  'Address',
                  width: 140,
                  hint: '0x90000000',
                ),
                _inputField(_qspiReadSize, 'Size', width: 100, hint: '256'),
                PanelActionButton(
                  icon: Icons.download,
                  label: 'Read',
                  tooltipStr: 'qspi read <addr> <size>',
                  onPressed: () {
                    final addr = _qspiReadAddr.text.trim();
                    final size = _qspiReadSize.text.trim();
                    if (addr.isNotEmpty && size.isNotEmpty) {
                      _send('qspi read $addr $size');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('QSPI Write'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _qspiWriteAddr,
                  'Address',
                  width: 140,
                  hint: '0x90000000',
                ),
                _inputField(_qspiWriteVal, 'Value', width: 100, hint: '0xFF'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _qspiWriteAutoErase,
                        onChanged: (v) =>
                            setState(() => _qspiWriteAutoErase = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Auto Erase', style: TextStyle(fontSize: 12)),
                  ],
                ),
                PanelActionButton(
                  icon: Icons.upload,
                  label: 'Write',
                  tooltipStr: _qspiWriteAutoErase
                      ? 'qspi write <addr> <val> erase'
                      : 'qspi write <addr> <val>',
                  onPressed: () {
                    final addr = _qspiWriteAddr.text.trim();
                    final val = _qspiWriteVal.text.trim();
                    if (addr.isNotEmpty && val.isNotEmpty) {
                      final eraseOpt = _qspiWriteAutoErase ? 'erase' : '';
                      _send('qspi write $addr $val $eraseOpt');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('QSPI Erase Sector'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _qspiEraseAddr,
                  'Address',
                  width: 140,
                  hint: '0x90000000',
                ),
                _inputField(_qspiEraseSize, 'Size', width: 100, hint: '4096'),
                PanelActionButton(
                  icon: Icons.delete_sweep,
                  label: 'Erase Sector',
                  tooltipStr: 'qspi erase <addr> <size>',
                  onPressed: () {
                    final addr = _qspiEraseAddr.text.trim();
                    final size = _qspiEraseSize.text.trim();
                    if (addr.isNotEmpty && size.isNotEmpty) {
                      _send('qspi erase $addr $size');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.sd_card,
        title: 'Storage — SD Card',
        subtitle:
            'SD card status, mount, unmount, file operations (ls, cat, write, read, append, rm, mkdir) & test',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Status',
                  'sd status',
                  'Check SD card status',
                  Icons.info_outline,
                ),
                _btn(
                  'Mount',
                  'sd mount',
                  'Mount SD card filesystem',
                  Icons.folder_open,
                ),
                _btn(
                  'Unmount',
                  'sd unmount',
                  'Unmount SD card filesystem',
                  Icons.folder_off,
                ),
                _btn(
                  'Format',
                  'sd format',
                  'Format SD card filesystem',
                  Icons.cleaning_services,
                ),
                _btn(
                  'SD Test',
                  'sd test',
                  'Run SD card speed/integrity test',
                  Icons.science,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Directory & View (ls / cat)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_sdLsPath, 'Path', width: 160, hint: '/SD:'),
                PanelActionButton(
                  icon: Icons.list_alt,
                  label: 'ls',
                  tooltipStr: 'sd ls [path]',
                  onPressed: () {
                    final path = _sdLsPath.text.trim();
                    _send(path.isEmpty ? 'sd ls' : 'sd ls $path');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Read / Write / Append File'),
            // Wrap(
            //   spacing: 8,
            //   runSpacing: 8,
            //   crossAxisAlignment: WrapCrossAlignment.center,
            //   children: [
            //     _inputField(_sdReadPath, 'Read File', width: 140),
            //     _inputField(_sdReadLen, 'Length', width: 90),
            //     PanelActionButton(
            //       icon: Icons.file_open,
            //       label: 'Read',
            //       tooltipStr: 'sd read <path> [len]',
            //       onPressed: () {
            //         final p = _sdReadPath.text.trim();
            //         final l = _sdReadLen.text.trim();
            //         if (p.isNotEmpty) {
            //           _send(l.isNotEmpty ? 'sd read $p $l' : 'sd read $p');
            //         }
            //       },
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_sdWritePath, 'Write File', width: 140),
                _inputField(_sdWriteContent, 'Content', width: 180),
                PanelActionButton(
                  icon: Icons.edit_note,
                  label: 'Write',
                  tooltipStr: 'sd write <path> <content>',
                  onPressed: () {
                    final p = _sdWritePath.text.trim();
                    final c = _sdWriteContent.text.trim();
                    if (p.isNotEmpty) _send('sd write $p "$c"');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_sdAppendPath, 'Append File', width: 140),
                _inputField(_sdAppendContent, 'Content', width: 180),
                PanelActionButton(
                  icon: Icons.post_add,
                  label: 'Append',
                  tooltipStr: 'sd append <path> <content>',
                  onPressed: () {
                    final p = _sdAppendPath.text.trim();
                    final c = _sdAppendContent.text.trim();
                    if (p.isNotEmpty) _send('sd append $p "$c"');
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _sdCatPath,
                  'File Path',
                  width: 160,
                  hint: '/test.txt',
                ),
                PanelActionButton(
                  icon: Icons.text_snippet,
                  label: 'cat',
                  tooltipStr: 'sd cat <path>',
                  onPressed: () {
                    final path = _sdCatPath.text.trim();
                    if (path.isNotEmpty) _send('sd cat $path');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Remove File & Make Directory'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_sdRmPath, 'Remove Path', width: 160),
                PanelActionButton(
                  icon: Icons.delete_outline,
                  label: 'rm',
                  tooltipStr: 'sd rm <path>',
                  onPressed: () {
                    final p = _sdRmPath.text.trim();
                    if (p.isNotEmpty) _send('sd rm $p');
                  },
                ),
                _inputField(_sdMkdirPath, 'New Dir Path', width: 160),
                PanelActionButton(
                  icon: Icons.create_new_folder,
                  label: 'mkdir',
                  tooltipStr: 'sd mkdir <path>',
                  onPressed: () {
                    final p = _sdMkdirPath.text.trim();
                    if (p.isNotEmpty) _send('sd mkdir $p');
                  },
                ),
                PanelActionButton(
                  icon: Icons.delete_outline,
                  label: 'rm dir',
                  tooltipStr: 'sd rm <path>',
                  onPressed: () {
                    final p = _sdMkdirPath.text.trim();
                    if (p.isNotEmpty) _send('sd rm $p');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ===========================================================================
  // 4. ETHERNET SUB PANEL
  // ===========================================================================
  List<Widget> _buildEthernetSubpanel() {
    return [
      MyPanelBody(
        icon: Icons.lan,
        title: 'Ethernet — Configuration & Diagnostics',
        subtitle: 'Check status, DHCP mode, set static IP, and ping test',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Status & DHCP'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Check Status',
                  'eth status',
                  'Check Ethernet link & IP status',
                  Icons.info_outline,
                ),
                _btn(
                  'DHCP Start',
                  'eth dhcp',
                  'Start DHCP client',
                  Icons.autorenew,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Set Static IP'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethIp, 'IP Address', width: 140),
                _inputField(_ethNetmask, 'Netmask', width: 140),
                _inputField(_ethGw, 'Gateway', width: 140),
                PanelActionButton(
                  icon: Icons.settings_ethernet,
                  label: 'Set IP',
                  tooltipStr: 'eth setip <ip> <netmask> <gw>',
                  onPressed: () {
                    final ip = _ethIp.text.trim();
                    final nm = _ethNetmask.text.trim();
                    final gw = _ethGw.text.trim();
                    if (ip.isNotEmpty && nm.isNotEmpty && gw.isNotEmpty) {
                      _send('eth setip $ip $nm $gw');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Ping Test'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethPingTarget, 'Target Host/IP', width: 180),
                PanelActionButton(
                  icon: Icons.network_ping,
                  label: 'Ping',
                  tooltipStr: 'eth ping <target>',
                  onPressed: () {
                    final t = _ethPingTarget.text.trim();
                    if (t.isNotEmpty) _send('eth ping $t');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.swap_calls,
        title: 'Ethernet — UDP & TCP Sockets',
        subtitle: 'Send and receive UDP / TCP datagrams and packets',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('UDP Datagrams'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethUdpHost, 'Host', width: 130),
                _inputField(_ethUdpPort, 'Port', width: 80),
                _inputField(_ethUdpData, 'Data', width: 160),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send UDP',
                  tooltipStr: 'eth sendudp <host> <port> <data>',
                  onPressed: () {
                    final h = _ethUdpHost.text.trim();
                    final p = _ethUdpPort.text.trim();
                    final d = _ethUdpData.text.trim();
                    if (h.isNotEmpty && p.isNotEmpty && d.isNotEmpty) {
                      _send('eth sendudp $h $p "$d"');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethUdpRecvPort, 'Recv Port', width: 100),
                PanelActionButton(
                  icon: Icons.call_received,
                  label: 'Recv UDP',
                  tooltipStr: 'eth recvudp <port>',
                  onPressed: () {
                    final p = _ethUdpRecvPort.text.trim();
                    if (p.isNotEmpty) _send('eth recvudp $p');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('TCP Packets'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethTcpHost, 'Host', width: 130),
                _inputField(_ethTcpPort, 'Port', width: 80),
                _inputField(_ethTcpData, 'Data', width: 160),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send TCP',
                  tooltipStr: 'eth sendtcp <host> <port> <data>',
                  onPressed: () {
                    final h = _ethTcpHost.text.trim();
                    final p = _ethTcpPort.text.trim();
                    final d = _ethTcpData.text.trim();
                    if (h.isNotEmpty && p.isNotEmpty && d.isNotEmpty) {
                      _send('eth sendtcp $h $p "$d"');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_ethTcpRecvPort, 'Recv Port', width: 100),
                PanelActionButton(
                  icon: Icons.call_received,
                  label: 'Recv TCP',
                  tooltipStr: 'eth recvtcp <port>',
                  onPressed: () {
                    final p = _ethTcpRecvPort.text.trim();
                    if (p.isNotEmpty) _send('eth recvtcp $p');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ===========================================================================
  // 5. LCD SUB PANEL
  // ===========================================================================
  List<Widget> _buildLcdSubpanel() {
    return [
      MyPanelBody(
        icon: Icons.desktop_windows,
        title: 'LCD — Status, Clear & Touch Control',
        subtitle:
            'LCD display status, clear screen with color, and touch panel on/off/status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Display & Clear'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'LCD Status',
                  'lcd status',
                  'Check LCD display controller status',
                  Icons.info_outline,
                ),
                _inputField(
                  _lcdClearColor,
                  'Color (Hex)',
                  width: 110,
                  hint: '0x0000',
                ),
                PanelActionButton(
                  icon: Icons.clear,
                  label: 'Clear Screen',
                  tooltipStr: 'lcd clear [color]',
                  onPressed: () {
                    final c = _lcdClearColor.text.trim();
                    _send(c.isEmpty ? 'lcd clear' : 'lcd clear $c');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('LCD Orientation'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Normal',
                  'lcd rotate normal',
                  'Normal landscape (480x272)',
                  Icons.screen_lock_landscape,
                ),
                _btn(
                  'Rotate Right',
                  'lcd rotate right',
                  '90° Clockwise portrait (272x480)',
                  Icons.screen_lock_portrait,
                ),
                _btn(
                  'Rotate 180',
                  'lcd rotate 180',
                  '180° Inverted landscape (480x272)',
                  Icons.screen_rotation,
                ),
                _btn(
                  'Rotate Left',
                  'lcd rotate left',
                  '270° Clockwise portrait (272x480)',
                  Icons.screen_lock_portrait,
                ),
                _btn(
                  'Mirror H',
                  'lcd rotate mirror_h',
                  'Horizontal Mirror (480x272)',
                  Icons.flip,
                ),
                _btn(
                  'Mirror V',
                  'lcd rotate mirror_v',
                  'Vertical Mirror (480x272)',
                  Icons.flip_camera_android,
                ),
                _btn(
                  'Orientation Status',
                  'lcd rotate status',
                  'Query LCD orientation status',
                  Icons.info_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Touch Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _btn(
                  'Touch Draw On',
                  'lcd touch draw_on',
                  'Enable capacitive touch drawing',
                  Icons.touch_app,
                ),
                _btn(
                  'Touch Draw Off',
                  'lcd touch draw_off',
                  'Disable capacitive touch drawing',
                  Icons.touch_app_outlined,
                ),
                _btn(
                  'Touch status',
                  'lcd touch',
                  'Check capacitive touch panel status',
                  Icons.info_outline,
                ),
                _inputField(
                  _lcdTouchDrawColor,
                  'Draw Color',
                  width: 100,
                  hint: '0xF800',
                ),
                PanelActionButton(
                  icon: Icons.palette,
                  label: 'Touch Draw Color',
                  tooltipStr: 'lcd touch draw_color <color>',
                  onPressed: () {
                    final c = _lcdTouchDrawColor.text.trim();
                    if (c.isNotEmpty) {
                      _send('lcd touch color $c');
                    }
                  },
                ),
                _btn(
                  'Touch Log Enable',
                  'lcd touch log 1',
                  'Enable touch panel logging',
                  Icons.info_outline,
                ),
                _btn(
                  'Touch log disable',
                  'lcd touch log 0',
                  'Disable touch panel logging',
                  Icons.info_outline,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.draw,
        title: 'LCD — Graphics Drawing Commands',
        subtitle:
            'Draw box, circle, line, fill rect/circle, and print string on LCD screen',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Draw Box & Fill Rect'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdBoxX, 'X', width: 60),
                _inputField(_lcdBoxY, 'Y', width: 60),
                _inputField(_lcdBoxW, 'W', width: 60),
                _inputField(_lcdBoxH, 'H', width: 60),
                _inputField(_lcdBoxColor, 'Color', width: 90),
                PanelActionButton(
                  icon: Icons.crop_square,
                  label: 'Draw Box',
                  tooltipStr: 'lcd box <x> <y> <w> <h> [color]',
                  onPressed: () {
                    _send(
                      'lcd box ${_lcdBoxX.text} ${_lcdBoxY.text} ${_lcdBoxW.text} ${_lcdBoxH.text} ${_lcdBoxColor.text}',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdFillRectX, 'X', width: 60),
                _inputField(_lcdFillRectY, 'Y', width: 60),
                _inputField(_lcdFillRectW, 'W', width: 60),
                _inputField(_lcdFillRectH, 'H', width: 60),
                _inputField(_lcdFillRectColor, 'Color', width: 90),
                PanelActionButton(
                  icon: Icons.square,
                  label: 'Fill Rect',
                  tooltipStr: 'lcd rect <x> <y> <w> <h> [color]',
                  onPressed: () {
                    _send(
                      'lcd rect ${_lcdFillRectX.text} ${_lcdFillRectY.text} ${_lcdFillRectW.text} ${_lcdFillRectH.text} ${_lcdFillRectColor.text}',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Draw Circle & Fill Circle'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdCircleX, 'X', width: 60),
                _inputField(_lcdCircleY, 'Y', width: 60),
                _inputField(_lcdCircleR, 'R', width: 60),
                _inputField(_lcdCircleColor, 'Color', width: 90),
                PanelActionButton(
                  icon: Icons.radio_button_unchecked,
                  label: 'Draw Circle',
                  tooltipStr: 'lcd circle <x> <y> <r> [color]',
                  onPressed: () {
                    _send(
                      'lcd circle ${_lcdCircleX.text} ${_lcdCircleY.text} ${_lcdCircleR.text} ${_lcdCircleColor.text}',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdFillCircleX, 'X', width: 60),
                _inputField(_lcdFillCircleY, 'Y', width: 60),
                _inputField(_lcdFillCircleR, 'R', width: 60),
                _inputField(_lcdFillCircleColor, 'Color', width: 90),
                PanelActionButton(
                  icon: Icons.circle,
                  label: 'Fill Circle',
                  tooltipStr: 'lcd circle <x> <y> <r> [color] [fill]',
                  onPressed: () {
                    _send(
                      'lcd circle ${_lcdFillCircleX.text} ${_lcdFillCircleY.text} ${_lcdFillCircleR.text} ${_lcdFillCircleColor.text} fill',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Draw Line'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdLineX1, 'X1', width: 60),
                _inputField(_lcdLineY1, 'Y1', width: 60),
                _inputField(_lcdLineX2, 'X2', width: 60),
                _inputField(_lcdLineY2, 'Y2', width: 60),
                _inputField(_lcdLineColor, 'Color', width: 90),
                PanelActionButton(
                  icon: Icons.show_chart,
                  label: 'Draw Line',
                  tooltipStr: 'lcd line <x1> <y1> <x2> <y2> [color]',
                  onPressed: () {
                    _send(
                      'lcd line ${_lcdLineX1.text} ${_lcdLineY1.text} ${_lcdLineX2.text} ${_lcdLineY2.text} ${_lcdLineColor.text}',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Print String'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_lcdPrintX, 'X', width: 60),
                _inputField(_lcdPrintY, 'Y', width: 60),
                buildDropdown<String>(
                  context,
                  value: _lcdPrintFontSize,
                  items: const [
                    DropdownMenuItem(value: 'small', child: Text('small')),
                    DropdownMenuItem(value: 'medium', child: Text('medium')),
                    DropdownMenuItem(value: 'large', child: Text('large')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _lcdPrintFontSize = v);
                  },
                  width: 95,
                ),
                _inputField(_lcdPrintStr, 'String', width: 160),
                _inputField(
                  _lcdPrintFgColor,
                  'FG Color',
                  width: 85,
                  hint: '0xFFFF',
                ),
                _inputField(
                  _lcdPrintBgColor,
                  'BG Color',
                  width: 85,
                  hint: 'BG (opt)',
                ),
                PanelActionButton(
                  icon: Icons.text_fields,
                  label: 'Print String',
                  tooltipStr:
                      'lcd print <x> <y> <small|medium|large> "<text>" [fg_color] [bg_color]',
                  onPressed: () {
                    final x = _lcdPrintX.text.trim();
                    final y = _lcdPrintY.text.trim();
                    final str = _lcdPrintStr.text.trim();
                    final fg = _lcdPrintFgColor.text.trim();
                    final bg = _lcdPrintBgColor.text.trim();
                    String cmd = 'lcd print $x $y $_lcdPrintFontSize "$str"';
                    if (fg.isNotEmpty) {
                      cmd += ' $fg';
                      if (bg.isNotEmpty) {
                        cmd += ' $bg';
                      }
                    }
                    _send(cmd);
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
