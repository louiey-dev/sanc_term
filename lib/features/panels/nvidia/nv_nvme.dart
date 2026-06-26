import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// NVMe info + dd/fio benchmark commands. Output (including dd/fio progress)
/// streams into the terminal pane. (Live speed parsing is a follow-up that
/// needs a console output stream.)
class NvNvmePanel extends ConsumerStatefulWidget {
  const NvNvmePanel({super.key});

  @override
  ConsumerState<NvNvmePanel> createState() => _NvNvmePanelState();
}

class _NvNvmePanelState extends ConsumerState<NvNvmePanel> {
  final _dev = TextEditingController(text: '/dev/nvme0n1');

  @override
  void dispose() {
    _dev.dispose();
    super.dispose();
  }

  PanelActionButton _cmd(
    IconData icon,
    String label,
    String command, {
    String? tip,
  }) => PanelActionButton(
    icon: icon,
    label: label,
    tooltipStr: tip ?? command,
    onPressed: () => sendBoardCommand(ref, context, command),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.storage,
      panelTitle: 'nVidia NVMe',
      panelSubtitle: 'NVMe info and throughput benchmarks',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.storage,
          title: 'NVMe Devices',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'sudo apt update && sudo apt install -y fio hdparm',
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _cmd(Icons.storage, 'List NVMe', 'sudo nvme list'),
                  _cmd(Icons.storage, 'lsblk', 'lsblk -f'),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: TextField(
                      controller: _dev,
                      decoration: const InputDecoration(
                        labelText: 'Device',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  _cmd(
                    Icons.info,
                    'Device info',
                    'sudo hdparm -gtT ${_dev.text}',
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.speed,
          title: 'NVMe Benchmarks',
          subtitle: 'Watch progress in the terminal pane',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cmd(
                Icons.delete_outline,
                'Remove Test Files',
                'rm -f ./testfile randread* seqread* fiotest',
              ),
              _cmd(
                Icons.upload,
                'Write Check (dd)',
                'dd if=/dev/zero of=./testfile bs=1M count=1024 oflag=direct status=progress',
              ),
              _cmd(
                Icons.download,
                'Read Check (dd)',
                'sync && echo 3 | sudo tee /proc/sys/vm/drop_caches; dd if=./testfile of=/dev/null bs=1M status=progress',
              ),
              _cmd(
                Icons.speed,
                'Read Throughput (fio)',
                'fio --name=seqread --rw=read --bs=1M --size=1G --numjobs=1 --iodepth=32 --direct=1 --ioengine=libaio --filename=./fiotest --group_reporting',
              ),
              _cmd(
                Icons.speed,
                'Write Throughput (fio)',
                'fio --name=randwrite --rw=randwrite --bs=4k --size=1G --numjobs=1 --iodepth=64 --direct=1 --ioengine=libaio --filename=./fiotest --group_reporting',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
