import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/widgets/project_editor/module_sidebar.dart';

/// Mobile layout for the project editor with drawer navigation.
class ProjectEditorMobileLayout extends StatelessWidget {
  final String currentModuleName;
  final bool showModuleActions;
  final bool showFindReplace;
  final bool isHistoryPanelVisible;
  final String selectionLabel;
  final String addLabel;
  final VoidCallback onShowSelectionDialog;
  final VoidCallback onToggleHistoryPanel;
  final VoidCallback onOpenFindReplace;
  final VoidCallback onOpenSettings;
  final VoidCallback onFloatingAction;
  final Widget moduleContent;
  final Widget? historyPanel;
  final List<Map<String, dynamic>> moduleItems;
  final int selectedModuleIndex;
  final ValueChanged<int> onModuleTapped;
  final String projectTitle;
  final VoidCallback onGoHome;

  const ProjectEditorMobileLayout({
    super.key,
    required this.currentModuleName,
    required this.showModuleActions,
    required this.showFindReplace,
    required this.isHistoryPanelVisible,
    required this.selectionLabel,
    required this.addLabel,
    required this.onShowSelectionDialog,
    required this.onToggleHistoryPanel,
    required this.onOpenFindReplace,
    required this.onOpenSettings,
    required this.onFloatingAction,
    required this.moduleContent,
    required this.historyPanel,
    required this.moduleItems,
    required this.selectedModuleIndex,
    required this.onModuleTapped,
    required this.projectTitle,
    required this.onGoHome,
  });

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'select':
        onShowSelectionDialog();
        break;
      case 'history':
        onToggleHistoryPanel();
        break;
      case 'find_replace':
        onOpenFindReplace();
        break;
      case 'add':
        onFloatingAction();
        break;
      case 'settings':
        onOpenSettings();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentModuleName),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (showModuleActions)
            PopupMenuButton<String>(
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'select',
                  child: Text(selectionLabel),
                ),
                PopupMenuItem<String>(
                  value: 'history',
                  child: Text(
                    isHistoryPanelVisible ? 'Hide History' : 'Show History',
                  ),
                ),
                if (showFindReplace)
                  const PopupMenuItem<String>(
                    value: 'find_replace',
                    child: Text('Find and Replace'),
                  ),
                PopupMenuItem<String>(value: 'add', child: Text(addLabel)),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ],
            ),
        ],
      ),
      drawer: Drawer(
        child: ModuleSidebar(
          isExpanded: true,
          moduleItems: moduleItems,
          selectedIndex: selectedModuleIndex,
          onModuleTapped: (index) {
            onModuleTapped(index);
            Navigator.of(context).pop();
          },
          onToggleExpanded: () {},
          projectTitle: projectTitle,
          onGoHome: () {
            onGoHome();
            Navigator.of(context).pop();
          },
          onOpenSettings: () {
            onOpenSettings();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: moduleContent),
          if (isHistoryPanelVisible && historyPanel != null)
            SizedBox(height: 200, child: historyPanel),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onFloatingAction,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
