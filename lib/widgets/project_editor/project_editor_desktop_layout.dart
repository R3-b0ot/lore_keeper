import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/project_editor/module_sidebar.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_item.dart';
import 'package:lore_keeper/widgets/project_editor/specific_functions_bar.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';

/// Desktop layout for the project editor with sidebar, content, and tools.
class ProjectEditorDesktopLayout extends StatelessWidget {
  final bool isSidebarExpanded;
  final bool isListPaneCollapsed;
  final List<ProjectEditorModuleItem> moduleItems;
  final int selectedModuleIndex;
  final ValueChanged<int> onModuleTapped;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleListPane;
  final String projectTitle;
  final VoidCallback onGoHome;
  final VoidCallback onOpenSettings;
  final Widget secondColumn;
  final Widget moduleContent;
  final bool showSecondColumnDivider;
  final bool isHistoryPanelVisible;
  final Widget? historyPanel;
  final bool showHistoryButton;
  final VoidCallback onToggleHistoryPanel;
  final VoidCallback? onFindReplacePressed;

  const ProjectEditorDesktopLayout({
    super.key,
    required this.isSidebarExpanded,
    required this.isListPaneCollapsed,
    required this.moduleItems,
    required this.selectedModuleIndex,
    required this.onModuleTapped,
    required this.onToggleSidebar,
    required this.onToggleListPane,
    required this.projectTitle,
    required this.onGoHome,
    required this.onOpenSettings,
    required this.secondColumn,
    required this.moduleContent,
    required this.showSecondColumnDivider,
    required this.isHistoryPanelVisible,
    required this.historyPanel,
    required this.showHistoryButton,
    required this.onToggleHistoryPanel,
    required this.onFindReplacePressed,
  });

  @override
  Widget build(BuildContext context) {
    const double collapsedWidth = 60.0;
    const double expandedWidth = 200.0;

    return Scaffold(
      appBar: null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.medium;
          final veryCompact = constraints.maxWidth < 720;
          final effectiveSidebarExpanded = isSidebarExpanded && !compact;
          final showHistoryPanel =
              isHistoryPanelVisible && historyPanel != null && !veryCompact;
          final showSecondColumn =
              showSecondColumnDivider && constraints.maxWidth >= 760;

          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: effectiveSidebarExpanded
                    ? expandedWidth
                    : collapsedWidth,
                color: Theme.of(context).colorScheme.surface,
                child: ModuleSidebar(
                  isExpanded: effectiveSidebarExpanded,
                  moduleItems: moduleItems,
                  selectedIndex: selectedModuleIndex,
                  onModuleTapped: onModuleTapped,
                  onToggleExpanded: onToggleSidebar,
                  projectTitle: projectTitle,
                  onGoHome: onGoHome,
                  onOpenSettings: onOpenSettings,
                ),
              ),
              Expanded(
                child: _ListAndEditorArea(
                  secondColumn: secondColumn,
                  moduleContent: moduleContent,
                  showSecondColumnDivider: showSecondColumn,
                  isListPaneCollapsed: isListPaneCollapsed,
                  onToggleListPane: onToggleListPane,
                ),
              ),
              if (showHistoryPanel) ...[
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.transparent,
                ),
                Flexible(child: historyPanel!),
              ],
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.transparent,
              ),
              Container(
                width: 48,
                color: Theme.of(context).colorScheme.surface,
                child: SpecificFunctionsBar(
                  onHistoryPressed: onToggleHistoryPanel,
                  isHistoryVisible: isHistoryPanelVisible,
                  showHistoryButton: showHistoryButton,
                  onSettingsPressed: onOpenSettings,
                  onFindReplacePressed: onFindReplacePressed,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListAndEditorArea extends StatelessWidget {
  final Widget secondColumn;
  final Widget moduleContent;
  final bool showSecondColumnDivider;
  final bool isListPaneCollapsed;
  final VoidCallback onToggleListPane;

  const _ListAndEditorArea({
    required this.secondColumn,
    required this.moduleContent,
    required this.showSecondColumnDivider,
    required this.isListPaneCollapsed,
    required this.onToggleListPane,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetListPaneWidth =
            showSecondColumnDivider && !isListPaneCollapsed
            ? (maxWidth * 0.25).clamp(220.0, 340.0)
            : 0.0;
        const toggleSize = 38.0;
        final toggleLeft = targetListPaneWidth - (toggleSize / 2);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: targetListPaneWidth,
                  child: targetListPaneWidth == 0
                      ? const SizedBox.shrink()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          child: secondColumn,
                        ),
                ),
                if (showSecondColumnDivider)
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.transparent,
                  ),
                Expanded(child: moduleContent),
              ],
            ),
            if (showSecondColumnDivider)
              Positioned(
                left: toggleLeft,
                top: (constraints.maxHeight / 2) - (toggleSize / 2),
                child: _SplitToggleButton(
                  isCollapsed: isListPaneCollapsed,
                  onPressed: onToggleListPane,
                  size: toggleSize,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SplitToggleButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onPressed;
  final double size;

  const _SplitToggleButton({
    required this.isCollapsed,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isCollapsed ? Icons.chevron_right : Icons.chevron_left,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
