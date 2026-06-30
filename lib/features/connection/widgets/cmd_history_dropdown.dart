import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/features/panels/common/cmd_history_service.dart';

/// A dropdown menu for the connection bar that displays the command history,
/// allowing the user to send recent or favorite commands with a single click,
/// and type new commands without leaving the current panel.
class CmdHistoryDropdown extends ConsumerStatefulWidget {
  const CmdHistoryDropdown({super.key});

  @override
  ConsumerState<CmdHistoryDropdown> createState() => _CmdHistoryDropdownState();
}

class _CmdHistoryDropdownState extends ConsumerState<CmdHistoryDropdown> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(c.card),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: c.border),
          ),
        ),
      ),
      alignmentOffset: const Offset(0, 4),
      builder: (context, controller, child) {
        return SizedBox(
          height: 32,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: BorderSide(color: c.border),
              foregroundColor: c.foreground,
              textStyle: const TextStyle(fontSize: 12),
            ),
            icon: const Icon(Icons.history, size: 14),
            label: const Text('History'),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
      },
      menuChildren: [
        _CmdHistoryDropdownContent(
          onCommandSent: () => _menuController.close(),
        ),
      ],
    );
  }
}

class _CmdHistoryDropdownContent extends ConsumerStatefulWidget {
  final VoidCallback onCommandSent;

  const _CmdHistoryDropdownContent({
    required this.onCommandSent,
  });

  @override
  ConsumerState<_CmdHistoryDropdownContent> createState() =>
      __CmdHistoryDropdownContentState();
}

class __CmdHistoryDropdownContentState
    extends ConsumerState<_CmdHistoryDropdownContent> {
  final _cmdController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus the text field when the dropdown opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cmdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  CmdHistoryNotifier get _history =>
      ref.read(cmdHistoryNotifierProvider.notifier);

  void _run(String cmd) {
    final trimmed = cmd.trim();
    if (trimmed.isEmpty) return;
    sendBoardCommand(ref, context, trimmed);
    _history.addRecent(trimmed);
    _cmdController.clear();
    widget.onCommandSent();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final history = ref.watch(cmdHistoryNotifierProvider);
    final favorites = history.favorites;
    final recents = history.recents;

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: c.primary),
                const SizedBox(width: 8),
                Text(
                  'Command History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.foreground,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _cmdController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: c.foreground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a command…',
                        hintStyle: TextStyle(fontSize: 12, color: c.muted),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: c.primary),
                        ),
                      ),
                      onSubmitted: _run,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.send, size: 16, color: c.primary),
                  tooltip: 'Send',
                  onPressed: () => _run(_cmdController.text),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable list of Favorites and Recents
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Favorites Section
                  if (favorites.isNotEmpty) ...[
                    _SectionHeader(title: 'FAVORITES'),
                    ...favorites.map((f) => _CommandTile(
                          cmd: f,
                          icon: Icons.star,
                          iconColor: Colors.amber,
                          actionIcon: Icons.close,
                          actionTooltip: 'Unpin from favorites',
                          onTap: () => _run(f),
                          onAction: () => _history.unpin(f),
                        )),
                  ],

                  // Recents Section
                  if (recents.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'RECENT',
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _history.clearRecents,
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 10,
                            color: c.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ...recents.map((r) => _CommandTile(
                          cmd: r,
                          icon: Icons.replay,
                          iconColor: c.muted,
                          actionIcon: Icons.push_pin_outlined,
                          actionTooltip: 'Pin to favorites',
                          onTap: () => _run(r),
                          onAction: () => _history.pin(r),
                        )),
                  ],

                  if (favorites.isEmpty && recents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Text(
                        'No command history yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.muted,
              letterSpacing: 1.0,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final String cmd;
  final IconData icon;
  final Color iconColor;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _CommandTile({
    required this.cmd,
    required this.icon,
    required this.iconColor,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cmd,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: actionTooltip,
              child: SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  color: c.muted,
                  icon: Icon(actionIcon),
                  onPressed: onAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
