import 'package:flutter/material.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

class PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const PanelHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.foreground,
                ),
              ),
              SelectableText(subtitle, style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
        ),
        ...actions.map(
          (a) => Padding(padding: const EdgeInsets.only(left: 8), child: a),
        ),
      ],
    );
  }
}

class PanelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltipStr;

  const PanelActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.tooltipStr = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltipStr,
      child: SizedBox(
        height: 30,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            side: BorderSide(color: c.border),
            foregroundColor: c.foreground,
            textStyle: const TextStyle(fontSize: 11),
          ),
          icon: Icon(icon, size: 14),
          label: Text(label),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class PanelToggleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? tooltipStr;
  final bool initialValue;
  final ValueChanged<bool>? onToggle;

  const PanelToggleButton({
    super.key,
    required this.icon,
    required this.label,
    this.tooltipStr,
    this.initialValue = false,
    this.onToggle,
  });

  @override
  State<PanelToggleButton> createState() => _PanelToggleButtonState();
}

class _PanelToggleButtonState extends State<PanelToggleButton> {
  late bool _isToggled;

  @override
  void initState() {
    super.initState();
    _isToggled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: widget.tooltipStr ?? '',
      child: SizedBox(
        height: 30,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            side: BorderSide(color: _isToggled ? c.primary : c.border),
            backgroundColor: _isToggled ? c.primary : Colors.transparent,
            foregroundColor: _isToggled ? c.primaryForeground : c.foreground,
            textStyle: const TextStyle(fontSize: 11),
          ),
          icon: Icon(widget.icon, size: 14),
          label: Text(widget.label),
          onPressed: () {
            setState(() => _isToggled = !_isToggled);
            widget.onToggle?.call(_isToggled);
          },
        ),
      ),
    );
  }
}

class PanelBody extends StatelessWidget {
  final List<Widget> children;

  const PanelBody({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class MyPanel extends StatelessWidget {
  final String panelTitle;
  final String panelSubtitle;
  final List<Widget>? panelActions;
  final List<Widget> children;
  final double spacing;
  final IconData? icon;

  const MyPanel({
    super.key,
    required this.panelTitle,
    required this.panelSubtitle,
    required this.panelActions,
    required this.children,
    this.spacing = 10,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spaced = <Widget>[
      PanelHeader(
        icon: icon ?? Icons.settings,
        iconColor: c.primary,
        title: panelTitle,
        subtitle: panelSubtitle,
        actions: [...?panelActions],
      ),
      const SizedBox(height: 24),
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) SizedBox(height: spacing),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spaced,
    );
  }
}

/// A titled card section inside a [MyPanel]: an optional icon + title +
/// subtitle, an optional trailing action (e.g. a button), and the content.
/// Use one per logical block; a panel is a [MyPanel] whose children are these.
class MyPanelBody extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const MyPanelBody({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PanelBody(
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: c.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                  if (subtitle != null)
                    SelectableText(
                      subtitle!,
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
