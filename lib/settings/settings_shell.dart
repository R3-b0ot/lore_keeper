import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/settings/settings_global_panes.dart';
import 'package:lore_keeper/settings/settings_project_panes.dart';

/// A single entry in the settings navigation.
class _SettingNavItem {
  final String id;
  final String label;
  final IconData icon;

  const _SettingNavItem(this.id, this.label, this.icon);
}

/// Provides the full navigation model for a given scope + project context.
class _SettingsNav {
  static const _global = [
    _SettingNavItem('global-appearance', 'Appearance', LucideIcons.palette),
    _SettingNavItem('global-interface', 'Interface', LucideIcons.layout),
    _SettingNavItem('global-editor', 'Editor Defaults', LucideIcons.penTool),
    _SettingNavItem('global-proofing', 'Proofing', LucideIcons.spellCheck),
    _SettingNavItem('global-ai', 'AI Provider', LucideIcons.cpu),
    _SettingNavItem('global-storage', 'Storage', LucideIcons.hardDrive),
    _SettingNavItem('global-backup', 'Backup', LucideIcons.archive),
    _SettingNavItem(
      'global-import-export',
      'Import / Export',
      LucideIcons.import,
    ),
    _SettingNavItem(
      'global-shortcuts',
      'Keyboard Shortcuts',
      LucideIcons.keyboard,
    ),
    _SettingNavItem('global-about', 'About', LucideIcons.info),
  ];

  static const _project = [
    _SettingNavItem('project-identity', 'Identity & Status', LucideIcons.info),
    _SettingNavItem('project-manuscript', 'Manuscript', LucideIcons.bookOpen),
    _SettingNavItem('project-world', 'World Settings', LucideIcons.globe),
    _SettingNavItem('project-calendar', 'Calendar', LucideIcons.calendar),
    _SettingNavItem('project-timeline', 'Timeline', LucideIcons.gitCommit),
    _SettingNavItem('project-maps', 'Maps', LucideIcons.map),
    _SettingNavItem('project-encyclopedia', 'Encyclopedia', LucideIcons.book),
    _SettingNavItem('project-taxonomy', 'Taxonomy', LucideIcons.gitFork),
    _SettingNavItem('project-characters', 'Characters', LucideIcons.users),
    _SettingNavItem('project-locations', 'Locations', LucideIcons.mapPin),
    _SettingNavItem(
      'project-relationships',
      'Relationships',
      LucideIcons.gitBranch,
    ),
    _SettingNavItem('project-research', 'Research', LucideIcons.search),
    _SettingNavItem('project-proofing', 'Proofing', LucideIcons.spellCheck),
    _SettingNavItem('project-history', 'History', LucideIcons.history),
    _SettingNavItem(
      'project-appearance',
      'Project Appearance',
      LucideIcons.paintBucket,
    ),
    _SettingNavItem('project-danger', 'Danger Zone', LucideIcons.triangleAlert),
  ];

  static List<_SettingNavItem> forProject() => _project;
  static List<_SettingNavItem> forGlobal() => _global;
}

/// The scope of the currently-opened settings surface.
enum _ActiveScope { global, project }

/// The production Settings window.
///
/// Implements the design direction from the settings UI spec:
/// - independently scrollable left navigation grouped by scope
/// - independently scrollable content pane
/// - global (primary accent) vs project (indigo accent) differentiation
/// - reusable setting components backed by real providers
///
/// When [project] is null the dialog operates in global scope only.
class SettingsShell extends StatefulWidget {
  final Project? project;
  final int? moduleIndex;
  final ChapterListProvider? chapterProvider;
  final CharacterListProvider? characterProvider;
  final VoidCallback? onDictionaryOpened;
  final VoidCallback? onDeleteProject;

  const SettingsShell({
    super.key,
    this.project,
    this.moduleIndex,
    this.chapterProvider,
    this.characterProvider,
    this.onDictionaryOpened,
    this.onDeleteProject,
  });

  @override
  State<SettingsShell> createState() => _SettingsShellState();
}

class _SettingsShellState extends State<SettingsShell> {
  _ActiveScope _scope = _ActiveScope.global;
  String _selectedId = 'global-appearance';

  bool get _isProject => _scope == _ActiveScope.project;

  void _select(String id, _ActiveScope scope) {
    setState(() {
      _scope = scope;
      _selectedId = id;
    });
  }

  void _switchGlobal() {
    if (!_isProject) return;
    _select('global-appearance', _ActiveScope.global);
  }

  void _switchProject() {
    if (_isProject || widget.project == null) return;
    _select('project-identity', _ActiveScope.project);
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  Widget _buildNav() {
    final colors = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    Widget item(_SettingNavItem item) {
      final selected =
          _selectedId == item.id && _isProject == _isProjectAt(item);
      final accent = item.id.startsWith('project')
          ? const Color(0xFF818CF8)
          : colors.primary;
      return InkWell(
        onTap: () => _select(item.id, _scope),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected ? accent : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? accent : colors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget groupHeader(String title, {required bool project}) {
      final accent = project ? const Color(0xFF818CF8) : colors.primary;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    return Container(
      width: isCompact ? 220 : 248,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.settings, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    inherit: false,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  groupHeader('Global', project: false),
                  for (final navItem in _SettingsNav.forGlobal())
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: item(navItem),
                    ),
                  if (widget.project != null) ...[
                    groupHeader('Project', project: true),
                    for (final navItem in _SettingsNav.forProject())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: item(navItem),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isProjectAt(_SettingNavItem item) => item.id.startsWith('project');

  // ── Content ────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final project = _selectedId.startsWith('project') ? widget.project : null;

    return Expanded(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: _buildPane(_selectedId, project),
          ),
        ),
      ),
    );
  }

  Widget _buildPane(String id, Project? project) {
    return switch (id) {
      'global-appearance' => const GlobalAppearancePane(),
      'global-interface' => const GlobalInterfacePane(),
      'global-editor' => const GlobalEditorPane(),
      'global-proofing' => const GlobalProofingPane(),
      'global-ai' => const GlobalAiPane(),
      'global-storage' => const GlobalStoragePane(),
      'global-backup' => const GlobalBackupPane(),
      'global-import-export' => const GlobalImportExportPane(),
      'global-shortcuts' => const GlobalShortcutsPane(),
      'global-about' => const GlobalAboutPane(),
      'project-identity' => ProjectIdentityPane(project: project),
      'project-manuscript' => ProjectManuscriptPane(project: project),
      'project-world' => ProjectWorldPane(project: project),
      'project-calendar' => ProjectCalendarPane(project: project),
      'project-timeline' => ProjectTimelinePane(project: project),
      'project-maps' => ProjectMapsPane(project: project),
      'project-encyclopedia' => ProjectEncyclopediaPane(project: project),
      'project-taxonomy' => ProjectTaxonomyPane(project: project),
      'project-characters' => ProjectCharactersPane(project: project),
      'project-locations' => ProjectLocationsPane(project: project),
      'project-relationships' => ProjectRelationshipsPane(project: project),
      'project-research' => ProjectResearchPane(project: project),
      'project-proofing' => ProjectProofingPane(
        project: project,
        onDictionaryOpened: widget.onDictionaryOpened,
      ),
      'project-history' => ProjectHistoryPane(project: project),
      'project-appearance' => ProjectAppearancePane(project: project),
      'project-danger' => ProjectDangerPane(
        project: project,
        onDeleteProject: widget.onDeleteProject,
      ),
      _ => const _UnderConstructionPane(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with close button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(
            children: [
              const SizedBox(width: 220),
              Expanded(
                child: _ScopeToggle(
                  isProject: _isProject,
                  onGlobal: _switchGlobal,
                  onProject: _switchProject,
                  hasProject: widget.project != null,
                ),
              ),
              IconButton(
                tooltip: 'Close settings',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, size: 20),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildNav(), _buildContent()],
          ),
        ),
      ],
    );
  }
}

/// A scope switcher let the user jump between Global and Project sections.
class _ScopeToggle extends StatelessWidget {
  final bool isProject;
  final VoidCallback onGlobal;
  final VoidCallback onProject;
  final bool hasProject;

  const _ScopeToggle({
    required this.isProject,
    required this.onGlobal,
    required this.onProject,
    required this.hasProject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _scopePill(
          context: context,
          label: 'Global',
          active: !isProject,
          activeColor: colors.primary,
          onTap: onGlobal,
        ),
        const SizedBox(width: 8),
        if (hasProject)
          _scopePill(
            context: context,
            label: 'Project',
            active: isProject,
            activeColor: const Color(0xFF818CF8),
            onTap: onProject,
          ),
      ],
    );
  }

  Widget _scopePill({
    required BuildContext context,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.5)
                : colors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : colors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _UnderConstructionPane extends StatelessWidget {
  const _UnderConstructionPane();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.hammer, size: 40, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Under Construction',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'This module settings architecture is planned for a future update.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
