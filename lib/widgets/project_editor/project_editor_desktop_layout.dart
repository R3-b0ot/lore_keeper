import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/project_editor/module_sidebar.dart';
import 'package:lore_keeper/widgets/project_editor/specific_functions_bar.dart';

/// Desktop layout for the project editor with sidebar, content, and tools.
class ProjectEditorDesktopLayout extends StatelessWidget {
  final bool isSidebarExpanded;
  final List<Map<String, dynamic>> moduleItems;
  final int selectedModuleIndex;
  final ValueChanged<int> onModuleTapped;
  final VoidCallback onToggleSidebar;
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
  final bool isFindReplaceAvailable;

  const ProjectEditorDesktopLayout({
    super.key,
    required this.isSidebarExpanded,
    required this.moduleItems,
    required this.selectedModuleIndex,
    required this.onModuleTapped,
    required this.onToggleSidebar,
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
    required this.isFindReplaceAvailable,
  });

  @override
  Widget build(BuildContext context) {
    const double collapsedWidth = 60.0;
    const double expandedWidth = 200.0;

    return Scaffold(
      appBar: null,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: isSidebarExpanded ? expandedWidth : collapsedWidth,
            color: Theme.of(context).colorScheme.surface,
            child: ModuleSidebar(
              isExpanded: isSidebarExpanded,
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
            flex: 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 80),
              child: secondColumn,
            ),
          ),
          showSecondColumnDivider
              ? const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.transparent,
                )
              : const SizedBox.shrink(),
          Expanded(flex: 3, child: moduleContent),
          if (isHistoryPanelVisible && historyPanel != null) ...[
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.transparent,
            ),
            historyPanel!,
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
              isMobile: false,
              isFindReplaceAvailable: isFindReplaceAvailable,
            ),
          ),
        ],
      ),
    );
  }
}
