import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Keeps project editor navigation cohesive while isolating layout concerns
/// from the main screen implementation.
class ModuleSidebar extends StatelessWidget {
  final bool isExpanded;
  final List<Map<String, dynamic>> moduleItems;
  final int selectedIndex;
  final ValueChanged<int> onModuleTapped;
  final VoidCallback onToggleExpanded;
  final String projectTitle;
  final VoidCallback onGoHome;
  final VoidCallback onOpenSettings;

  const ModuleSidebar({
    super.key,
    required this.isExpanded,
    required this.moduleItems,
    required this.selectedIndex,
    required this.onModuleTapped,
    required this.onToggleExpanded,
    required this.projectTitle,
    required this.onGoHome,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Column(
            children: [
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(
                  isExpanded ? LucideIcons.x : LucideIcons.menu,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.star,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          projectTitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(LucideIcons.star, color: colorScheme.secondary, size: 24),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: moduleItems.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> item = moduleItems[index];
              return _ModuleSidebarItem(
                index: index,
                item: item,
                isSelected: index == selectedIndex,
                isExpanded: isExpanded,
                onTap: onModuleTapped,
              );
            },
          ),
        ),
        const Divider(height: 1),
        _FooterSidebarItem(
          icon: LucideIcons.house,
          label: 'Home',
          isExpanded: isExpanded,
          onTap: onGoHome,
        ),
        _FooterSidebarItem(
          icon: LucideIcons.settings,
          label: 'Settings',
          isExpanded: isExpanded,
          onTap: onOpenSettings,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ModuleSidebarItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool isSelected;
  final bool isExpanded;
  final ValueChanged<int> onTap;

  const _ModuleSidebarItem({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        height: 56,
        width: double.infinity,
        color: isSelected ? colorScheme.primaryContainer : null,
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 16)
            : EdgeInsets.zero,
        child: isExpanded
            ? Row(
                children: [
                  Icon(item['icon'] as IconData, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    item['label'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Tooltip(
                message: item['label'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, color: iconColor, size: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FooterSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FooterSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 16)
            : EdgeInsets.zero,
        child: isExpanded
            ? Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Tooltip(
                message: label,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(icon, color: iconColor, size: 20)],
                ),
              ),
      ),
    );
  }
}
