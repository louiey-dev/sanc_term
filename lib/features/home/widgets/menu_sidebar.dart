import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/models/panel_entry.dart';
import 'package:sanc_term/features/panels/panel_registry.dart';

final secretPanelsUnlockedProvider = StateProvider<bool>((ref) => false);

class MenuSidebar extends ConsumerWidget {
  const MenuSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isUnlocked = ref.watch(secretPanelsUnlockedProvider);
    final location = GoRouterState.of(context).uri.toString();
    final activePanelId = location.startsWith('/home/panel/')
        ? location.substring('/home/panel/'.length)
        : null;

    final visibleGroups = panelGroups
        .where((group) => !group.isHidden || isUnlocked)
        .map((group) {
          final visibleItems =
              group.items
                  .where((item) => !item.isHidden || isUnlocked)
                  .toList();
          return PanelGroup(
            title: group.title,
            icon: group.icon,
            items: visibleItems,
            isHidden: group.isHidden,
          );
        })
        .where((group) => group.items.isNotEmpty)
        .toList();

    final hasAnyActiveGroup = visibleGroups.any(
      (group) => group.items.any((e) => e.id == activePanelId),
    );

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: visibleGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = visibleGroups[groupIndex];
          final isGroupActive = group.items.any((e) => e.id == activePanelId);
          final shouldExpand = isGroupActive || (!hasAnyActiveGroup && groupIndex == 0);

          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              key: PageStorageKey('group_${group.title}'),
              initiallyExpanded: shouldExpand,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
              collapsedIconColor: isGroupActive ? c.primary : c.muted,
              iconColor: isGroupActive ? c.primary : c.muted,
              title: Row(
                children: [
                  Icon(
                    group.icon,
                    size: 14,
                    color: isGroupActive ? c.primary : c.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isGroupActive ? c.primary : c.muted,
                      letterSpacing: 2,
                    ),
                  ),
                  if (group.isHidden) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.visibility_off, size: 10, color: c.muted),
                  ],
                ],
              ),
              children: group.items
                  .map(
                    (entry) => _SideMenuItem(
                      entry: entry,
                      isActive: entry.id == activePanelId,
                      onTap: () => context.go('/home/panel/${entry.id}'),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final PanelEntry entry;
  final bool isActive;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.entry,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    entry.icon,
                    size: 16,
                    color: isActive ? c.primaryForeground : c.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? c.foreground
                              : c.foreground.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.description,
                        style: TextStyle(fontSize: 9, color: c.muted),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
