import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/connection/providers/board_profile_service.dart';
import 'package:sanc_term/features/connection/providers/serial_pane_provider.dart';
import 'package:sanc_term/shared/models/board_profile.dart';

class BoardProfilePicker extends ConsumerWidget {
  const BoardProfilePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profiles = ref.watch(boardProfilesNotifierProvider);

    return PopupMenuButton<String>(
      tooltip: 'Board profiles',
      color: c.card,
      icon: Icon(Icons.bookmarks_outlined, size: 16, color: c.muted),
      onSelected: (id) {
        if (id == '__save__') {
          _showSaveDialog(context, ref);
          return;
        }
        final profile = profiles.firstWhere((p) => p.id == id);
        final activeId = ref.read(effectiveActiveSerialTabIdProvider);
        if (activeId == null) return;
        final notifier =
            ref.read(serialPaneNotifierProvider(activeId).notifier);
        notifier.setPort(profile.port);
        notifier.setBaudRate(profile.baudRate);
      },
      itemBuilder: (context) => [
        if (profiles.isNotEmpty) ...[
          ...profiles.map(
            (p) => PopupMenuItem<String>(
              value: p.id,
              child: Row(
                children: [
                  Icon(
                    p.isDefault ? Icons.star : Icons.circle_outlined,
                    size: 14,
                    color: p.isDefault ? c.primary : c.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.name,
                    style: TextStyle(fontSize: 12, color: c.foreground),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.port} · ${p.baudRate}',
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<String>(
          value: '__save__',
          child: Row(
            children: [
              Icon(Icons.save_outlined, size: 14, color: c.muted),
              const SizedBox(width: 6),
              Text(
                'Save current config…',
                style: TextStyle(fontSize: 12, color: c.foreground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final nameCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(
          'Save profile',
          style: TextStyle(color: c.foreground, fontSize: 14),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: c.foreground),
          decoration: InputDecoration(
            hintText: 'Profile name',
            hintStyle: TextStyle(color: c.muted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.muted)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final activeId = ref.read(effectiveActiveSerialTabIdProvider);
              if (activeId == null) return;
              final config =
                  ref.read(serialPaneNotifierProvider(activeId)).config;
              final profile = BoardProfile(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                port: config.port,
                baudRate: config.baudRate,
              );
              ref.read(boardProfilesNotifierProvider.notifier).save(profile);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    ).then((_) => nameCtrl.dispose());
  }
}
