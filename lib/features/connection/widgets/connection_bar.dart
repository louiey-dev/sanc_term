import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/core/theme/theme_provider.dart';
import 'package:sanc_term/features/connection/providers/serial_config_notifier.dart';
import 'package:sanc_term/features/connection/providers/serial_pane_provider.dart';
import 'package:sanc_term/features/connection/widgets/board_profile_picker.dart';
import 'package:sanc_term/features/terminal/providers/terminal_instances.dart';
import 'package:sanc_term/shared/models/serial_config.dart';
import 'package:sanc_term/shared/widgets/common.dart';

const _baudRates = [
  9600,
  19200,
  38400,
  57600,
  115200,
  230400,
  460800,
  921600,
  1500000,
];

sealed class _SerialSetting {}

final class _SetEncoding extends _SerialSetting {
  _SetEncoding(this.value);
  final SerialEncoding value;
}

final class _SetNewLine extends _SerialSetting {
  _SetNewLine(this.value);
  final NewLine value;
}

class ConnectionBar extends ConsumerWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ports = ref.watch(availablePortsNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Resolve the SERIAL pane the bar currently controls.
    final activeId = ref.watch(effectiveActiveSerialTabIdProvider);
    final hasPane = activeId != null;
    final pane = hasPane
        ? ref.watch(serialPaneNotifierProvider(activeId))
        : const SerialPaneState();
    final paneN =
        hasPane ? ref.read(serialPaneNotifierProvider(activeId).notifier) : null;
    final config = pane.config;
    final isConnected = pane.isConnected;

    String? activeLabel;
    if (hasPane) {
      for (final t in ref.watch(terminalTabsNotifierProvider)) {
        if (t.id == activeId) activeLabel = t.label;
      }
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.terminal, size: 18, color: c.primary),
                  const SizedBox(width: 8),
                  Text(
                    'sanc_term',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Which SERIAL pane the bar acts on
                  _ActivePaneChip(label: activeLabel),
                  const SizedBox(width: 8),

                  const BoardProfilePicker(),
                  const SizedBox(width: 4),

                  _ToolbarButton(
                    icon: Icons.search,
                    label: 'Scan',
                    onPressed: isConnected
                        ? null
                        : () => ref
                            .read(availablePortsNotifierProvider.notifier)
                            .scan(),
                  ),
                  const SizedBox(width: 8),

                  buildDropdown<String>(
                    context,
                    value: config.port.isEmpty ? null : config.port,
                    hint: 'Port',
                    items: ports
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (!hasPane || isConnected)
                        ? null
                        : (v) {
                            if (v != null) paneN!.setPort(v);
                          },
                    width: 110,
                  ),

                  const ToolbarDivider(),

                  buildDropdown<int>(
                    context,
                    value: config.baudRate,
                    items: _baudRates
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              '$b',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (!hasPane || isConnected)
                        ? null
                        : (v) {
                            if (v != null) paneN!.setBaudRate(v);
                          },
                    width: 100,
                  ),

                  const ToolbarDivider(),

                  _SerialSettingsButton(
                    config: config,
                    paneNotifier: paneN,
                    enabled: hasPane && !isConnected,
                  ),

                  const ToolbarDivider(),

                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isConnected ? c.destructive : c.primary,
                        foregroundColor:
                            isConnected ? Colors.white : c.primaryForeground,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(
                        isConnected ? Icons.link_off : Icons.link,
                        size: 14,
                      ),
                      label: Text(isConnected ? 'Disconnect' : 'Connect'),
                      onPressed: (!hasPane || config.port.isEmpty)
                          ? null
                          : () {
                              if (isConnected) {
                                paneN!.disconnect();
                              } else {
                                paneN!.connect();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          Tooltip(
            message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: c.muted,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
          ),

          const SizedBox(width: 8),

          _StatusPill(
            config: config,
            isConnected: isConnected,
            hasPane: hasPane,
          ),
        ],
      ),
    );
  }
}

class _ActivePaneChip extends StatelessWidget {
  const _ActivePaneChip({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.adjust, size: 11, color: label != null ? c.primary : c.muted),
          const SizedBox(width: 5),
          Text(
            label ?? 'No SERIAL pane',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: label != null ? c.foreground : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SerialSettingsButton extends StatelessWidget {
  const _SerialSettingsButton({
    required this.config,
    required this.paneNotifier,
    required this.enabled,
  });

  final SerialConfig config;
  final SerialPaneNotifier? paneNotifier;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<_SerialSetting>(
      enabled: enabled,
      color: c.card,
      tooltip: 'Serial settings',
      onSelected: (setting) => switch (setting) {
        _SetEncoding(:final value) => paneNotifier?.setEncoding(value),
        _SetNewLine(:final value) => paneNotifier?.setNewLine(value),
      },
      itemBuilder: (_) => [
        PopupMenuItem<_SerialSetting>(
          enabled: false,
          height: 32,
          child: Text(
            'SERIAL SETTINGS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: c.muted,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_SerialSetting>(
          enabled: false,
          height: 28,
          child: Text('Encoding', style: TextStyle(fontSize: 11, color: c.muted)),
        ),
        for (final e in SerialEncoding.values)
          PopupMenuItem<_SerialSetting>(
            value: _SetEncoding(e),
            height: 36,
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 14,
                  color: config.encoding == e ? c.primary : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(e.label, style: TextStyle(fontSize: 12, color: c.foreground)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<_SerialSetting>(
          enabled: false,
          height: 28,
          child: Text('New Line', style: TextStyle(fontSize: 11, color: c.muted)),
        ),
        for (final n in NewLine.values)
          PopupMenuItem<_SerialSetting>(
            value: _SetNewLine(n),
            height: 36,
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 14,
                  color: config.newLine == n ? c.primary : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(n.label, style: TextStyle(fontSize: 12, color: c.foreground)),
              ],
            ),
          ),
      ],
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 14, color: c.foreground),
              const SizedBox(width: 6),
              Text('Settings', style: TextStyle(fontSize: 12, color: c.foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: c.border),
          foregroundColor: c.foreground,
          textStyle: const TextStyle(fontSize: 12),
        ),
        icon: Icon(icon, size: 14),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final SerialConfig config;
  final bool isConnected;
  final bool hasPane;

  const _StatusPill({
    required this.config,
    required this.isConnected,
    required this.hasPane,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = isConnected
        ? '${config.port}  |  ${config.baudRate}  |  ${config.encoding.label}  |  ${config.newLine.label}'
        : (hasPane ? 'Disconnected' : 'No serial pane');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? c.primary.withValues(alpha: 0.5) : c.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? c.primary : c.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Consolas',
              color: isConnected ? c.primary : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}
