import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/panel.dart';
import '../common/board_command.dart';

class NvUsbPanel extends ConsumerStatefulWidget {
  const NvUsbPanel({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NvUsbPanelState();
}

class _NvUsbPanelState extends ConsumerState<NvUsbPanel> {
  PanelActionButton _cmd(
    String label,
    String Function() command, {
    String? tip,
  }) => PanelActionButton(
    icon: Icons.usb,
    label: label,
    tooltipStr: tip ?? command(),
    onPressed: () => sendBoardCommand(ref, context, command()),
  );

  final _usbPath = TextEditingController(text: '/dev/sda');

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.usb,
      panelTitle: 'nVidia USB',
      panelSubtitle: 'USB configuration and base info',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.usb,
          title: 'USB Control',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cmd(
                tip: 'Run this on the Jetson',
                'List USB devices',
                () => 'lsusb',
              ),
              _cmd(
                tip: 'Run this on the Jetson',
                'Tree USB devices',
                () => 'lsusb -t',
              ),
              _cmd(
                tip: 'Run this on the Jetson',
                'verbose USB info',
                () => 'lsusb -v',
              ),
              _cmd(
                tip: 'Run this on the Jetson',
                'dmesg USB info',
                () => 'sudo dmesg | grep usb',
              ),
              _cmd(
                tip: 'Run this on the Jetson',
                'journalctl USB info',
                () => 'sudo journalctl -k | grep usb',
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.usb,
          title: 'USB Performance Test',
          subtitle:
              'You can check your USB speed via sudo lsusb -t | grep -E "Speed|Class"',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const SelectableText(
                '''fio (Flexible I/O Tester) must be installed on both ends of the test.
sudo apt update && sudo apt install -y fio\n
Connect a USB device to the Jetson and run the following commands on the Jetson (client side)\n
Step 1 : Maximize Clock Frequency
Step 2 : Run the Throughput Pipelines''',
              ),
              Row(
                spacing: 8,
                children: [
                  _cmd(
                    tip:
                        'Pin all 12 ARM cores and internal busses to absolute maximum performance',
                    'Max Clock',
                    () => 'sudo nvpmodel -m 0 && sudo jetson_clocks',
                  ),
                  _cmd(
                    tip: 'Check USB Speed/Class info',
                    'Tree USB devices',
                    () => 'lsusb -t',
                  ),
                  _cmd(tip: 'Check USB node name', 'node name', () => 'lsblk'),
                ],
              ),
              SizedBox(
                width: 120,
                height: 30,
                child: TextField(
                  controller: _usbPath,
                  decoration: const InputDecoration(
                    labelText: 'USB Path',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              _cmd(
                tip:
                    'Safe to run, does not destroy disk data because it only reads from the disk',
                'Run a Raw Direct Read test',
                () =>
                    'sudo fio --filename=${_usbPath.text} --direct=1 --rw=read --bs=1M --ioengine=libaio --iodepth=64 --runtime=30 --numjobs=1 --time_based --name=usb_test',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
