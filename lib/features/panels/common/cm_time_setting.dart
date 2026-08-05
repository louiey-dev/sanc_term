import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class CmTimeSettingPanel extends ConsumerStatefulWidget {
  const CmTimeSettingPanel({super.key});

  @override
  ConsumerState<CmTimeSettingPanel> createState() => _CmTimeSettingPanelState();
}

/// State model for preserving Time Setting panel parameters across page transitions
class CmTimeSettingParamsState {
  final String date;
  final String tz;

  const CmTimeSettingParamsState({
    this.date = '2026-01-01 00:00:00',
    this.tz = 'UTC',
  });
}

/// Riverpod provider for persisting Time Setting panel parameter values
final cmTimeSettingParamsProvider = StateProvider<CmTimeSettingParamsState>(
  (ref) => const CmTimeSettingParamsState(),
);

class _CmTimeSettingPanelState extends ConsumerState<CmTimeSettingPanel> {
  // `date -s` expects "YYYY-MM-DD HH:MM:SS".
  late final TextEditingController _date;
  late final TextEditingController _tz;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(cmTimeSettingParamsProvider);
    _date = TextEditingController(text: saved.date);
    _tz = TextEditingController(text: saved.tz);

    _date.addListener(_saveParams);
    _tz.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(cmTimeSettingParamsProvider.notifier).state =
        CmTimeSettingParamsState(date: _date.text, tz: _tz.text);
  }

  @override
  void dispose() {
    _date.dispose();
    _tz.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  @override
  Widget build(BuildContext context) {
    PanelActionButton btn(IconData i, String label, String cmd) =>
        PanelActionButton(
          icon: i,
          label: label,
          tooltipStr: cmd,
          onPressed: () => _send(cmd),
        );
    return MyPanel(
      icon: Icons.timer,
      panelTitle: 'Time Setting',
      panelSubtitle: 'Clock, timezone and NTP synchronization',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.access_time,
          title: 'Current Time',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.schedule, 'Date', 'date'),
              btn(Icons.public, 'timedatectl', 'timedatectl'),
              btn(Icons.watch, 'HW Clock', 'hwclock -r'),
              btn(Icons.sync, 'Sync HW→Sys', 'hwclock -s'),
              btn(Icons.sync_alt, 'Sync Sys→HW', 'hwclock -w'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.edit_calendar,
          title: 'Set System Date',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 40,
                child: TextField(
                  controller: _date,
                  decoration: const InputDecoration(
                    labelText: 'YYYY-MM-DD HH:MM:SS',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              PanelActionButton(
                icon: Icons.save,
                label: 'Set Date',
                tooltipStr: 'date -s',
                onPressed: () => _send('date -s "${_date.text}"'),
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.travel_explore,
          title: 'Timezone & NTP',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 40,
                child: TextField(
                  controller: _tz,
                  decoration: const InputDecoration(
                    labelText: 'Region/City',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              PanelActionButton(
                icon: Icons.public,
                label: 'Set Timezone',
                tooltipStr: 'timedatectl set-timezone',
                onPressed: () =>
                    _send('timedatectl set-timezone ${_tz.text}'),
              ),
              btn(Icons.list, 'List Zones', 'timedatectl list-timezones'),
              btn(Icons.sync, 'Enable NTP', 'timedatectl set-ntp true'),
            ],
          ),
        ),
      ],
    );
  }
}
