import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/settings/widgets/settings_widgets.dart';

/// Shared project pane header.
class _ProjectHeader extends StatelessWidget {
  final String title;
  final String description;
  final String projectName;

  const _ProjectHeader({
    required this.title,
    required this.description,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingScopeBadge(isProject: true, projectName: projectName),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _projectName(Project? project) => project?.title ?? 'Project';

/// Common helper for a text-field tile editing a project string field.
Widget _projectTextField({
  required Project project,
  required String title,
  String? description,
  required String? value,
  required ValueChanged<String> onChanged,
  String? hint,
  bool monospace = false,
}) {
  return SettingTextField(
    title: title,
    description: description,
    initialValue: value ?? '',
    hintText: hint,
    monospace: monospace,
    onChanged: (v) {
      onChanged(v);
      project.save();
    },
  );
}

/// PROJECT: Identity & Status.
class ProjectIdentityPane extends StatelessWidget {
  final Project? project;

  const ProjectIdentityPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final project = this.project;
    if (project == null) {
      return const _NoProjectPane();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Project Identity',
          description: 'Metadata and core details for this specific world.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Identity',
          children: [
            _projectTextField(
              project: project,
              title: 'Project Name',
              value: project.title,
              onChanged: (v) => project.title = v,
            ),
            _projectTextField(
              project: project,
              title: 'Book Title',
              description: 'The formal title of your manuscript.',
              value: project.bookTitle,
              hint: 'Optional',
              onChanged: (v) => project.bookTitle = v,
            ),
            _projectTextField(
              project: project,
              title: 'Author(s)',
              value: project.authors,
              hint: 'e.g. John Doe, Jane Smith',
              onChanged: (v) => project.authors = v,
            ),
            _projectTextField(
              project: project,
              title: 'Genre',
              value: project.genre,
              hint: 'e.g. Epic Fantasy',
              onChanged: (v) => project.genre = v,
            ),
          ],
        ),
        SettingSection(
          title: 'Synopsis',
          children: [_ProjectSynopsisField(project: project)],
        ),
      ],
    );
  }
}

class _ProjectSynopsisField extends StatefulWidget {
  final Project project;

  const _ProjectSynopsisField({required this.project});

  @override
  State<_ProjectSynopsisField> createState() => _ProjectSynopsisFieldState();
}

class _ProjectSynopsisFieldState extends State<_ProjectSynopsisField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.project.description ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        maxLines: 5,
        onChanged: (v) {
          widget.project.description = v;
          widget.project.save();
        },
        decoration: const InputDecoration(
          labelText: 'Global Synopsis',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// PROJECT: Manuscript.
class ProjectManuscriptPane extends StatelessWidget {
  final Project? project;

  const ProjectManuscriptPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final pn = _projectName(project);
    if (project == null) return const _NoProjectPane();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Manuscript',
          description:
              'Presentation and formatting of this project’s manuscript. Inherits global editor defaults where not overridden.',
          projectName: pn,
        ),
        SettingSection(
          title: 'Formatting',
          children: [
            SettingDropdown<String>(
              title: 'Manuscript format',
              value: 'Chapter-based',
              items: const [
                DropdownMenuItem(
                  value: 'Chapter-based',
                  child: Text('Chapter-based'),
                ),
                DropdownMenuItem(
                  value: 'Part-based',
                  child: Text('Part-based'),
                ),
              ],
              onChanged: (_) {},
            ),
            SettingTextField(
              title: 'Default project font',
              description: 'Overrides the global editor font for this project.',
              hintText: 'Inherit (Inter)',
              monospace: true,
            ),
            SettingSlider(
              title: 'Line spacing',
              value: 1.5,
              min: 1,
              max: 2.5,
              divisions: 15,
              labelFormatter: (v) => v.toStringAsFixed(1),
              onChanged: (_) {},
            ),
          ],
        ),
        SettingInfo(
          text:
              'Chapter numbering, scene breaks, headers and page numbers are configured by the project’s manuscript structure — not stored as global preferences.',
          icon: LucideIcons.info,
        ),
      ],
    );
  }
}

/// PROJECT: World Settings.
class ProjectWorldPane extends StatelessWidget {
  final Project? project;

  const ProjectWorldPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final pn = _projectName(project);
    if (project == null) return const _NoProjectPane();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'World Settings',
          description: 'Physical and temporal laws of this universe.',
          projectName: pn,
        ),
        SettingSection(
          title: 'World',
          children: [
            SettingDropdown<String>(
              title: 'Calendar system',
              value: 'Custom (10 months, 30 days)',
              items: const [
                DropdownMenuItem(
                  value: 'Standard Gregorian',
                  child: Text('Standard Gregorian'),
                ),
                DropdownMenuItem(
                  value: 'Custom (10 months, 30 days)',
                  child: Text('Custom (10 months, 30 days)'),
                ),
                DropdownMenuItem(
                  value: 'Lunar Cycle',
                  child: Text('Lunar Cycle'),
                ),
              ],
              onChanged: (_) {},
            ),
            SettingDropdown<String>(
              title: 'Measurement units',
              value: 'Fantasy/Custom (Leagues, spans)',
              items: const [
                DropdownMenuItem(value: 'Metric', child: Text('Metric')),
                DropdownMenuItem(value: 'Imperial', child: Text('Imperial')),
                DropdownMenuItem(
                  value: 'Fantasy/Custom (Leagues, spans)',
                  child: Text('Fantasy/Custom (Leagues, spans)'),
                ),
              ],
              onChanged: (_) {},
            ),
            SettingSwitch(
              title: 'Strict canon enforcement',
              description: 'Warn when characters appear before they are born.',
              value: true,
            ),
          ],
        ),
        SettingInfo(
          text:
              'World-specific concepts (calendar definitions, maps, naming conventions) remain project-scoped data.',
          icon: LucideIcons.globe,
        ),
      ],
    );
  }
}

/// PROJECT: Calendar.
class ProjectCalendarPane extends StatelessWidget {
  final Project? project;

  const ProjectCalendarPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Calendar',
          description:
              'Calendar definitions are project data and are configured via the Calendar module.',
          projectName: _projectName(project),
        ),
        SettingInfo(
          text:
              'Months, week structure, leap rules, eras and conversions are managed as project calendars — not application preferences. Open the Calendar module to define them.',
          icon: LucideIcons.calendar,
        ),
      ],
    );
  }
}

/// PROJECT: Timeline.
class ProjectTimelinePane extends StatelessWidget {
  final Project? project;

  const ProjectTimelinePane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Timeline',
          description: 'Display and chronology preferences for this world.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Display',
          children: [
            SettingDropdown<String>(
              title: 'Default timeline scale',
              value: 'Year',
              items: const [
                DropdownMenuItem(value: 'Decade', child: Text('Decade')),
                DropdownMenuItem(value: 'Year', child: Text('Year')),
                DropdownMenuItem(value: 'Month', child: Text('Month')),
              ],
              onChanged: (_) {},
            ),
            SettingSlider(
              title: 'Default zoom',
              value: 100,
              min: 25,
              max: 400,
              divisions: 15,
              labelFormatter: (v) => '${v.round()}%',
              onChanged: (_) {},
            ),
          ],
        ),
        SettingInfo(
          text:
              'Timeline events themselves remain project data and are never stored as settings.',
          icon: LucideIcons.gitCommit,
        ),
      ],
    );
  }
}

/// PROJECT: Maps.
class ProjectMapsPane extends StatelessWidget {
  final Project? project;

  const ProjectMapsPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Maps',
          description: 'Presentation defaults for project maps.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Presentation',
          children: [
            SettingSwitch(title: 'Show grid', value: false),
            SettingSwitch(title: 'Show labels', value: true),
            SettingSwitch(title: 'Show legend', value: true),
            SettingSwitch(title: 'Show scale', value: true),
          ],
        ),
        SettingInfo(
          text: 'Map definitions and markers remain project-scoped data.',
          icon: LucideIcons.map,
        ),
      ],
    );
  }
}

/// PROJECT: Encyclopedia.
class ProjectEncyclopediaPane extends StatelessWidget {
  final Project? project;

  const ProjectEncyclopediaPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Encyclopedia',
          description:
              'Presentation and behaviour of the project encyclopedia.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Presentation',
          children: const [
            SettingSwitch(title: 'Show aliases', value: true),
            SettingSwitch(title: 'Show references', value: true),
            SettingSwitch(title: 'Show backlinks', value: true),
            SettingSwitch(title: 'Automatic summaries', value: false),
          ],
        ),
      ],
    );
  }
}

/// PROJECT: Taxonomy.
class ProjectTaxonomyPane extends StatelessWidget {
  final Project? project;

  const ProjectTaxonomyPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Taxonomy',
          description: 'Classification rules that belong to this world.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Classification',
          children: const [
            SettingSwitch(title: 'Auto classification', value: false),
            SettingSwitch(title: 'AI classification', value: false),
            SettingSwitch(title: 'Canon enforcement', value: true),
          ],
        ),
        SettingInfo(
          text:
              'Custom ranks and hierarchy depth are configured in the taxonomy module.',
          icon: LucideIcons.gitFork,
        ),
      ],
    );
  }
}

/// PROJECT: Characters.
class ProjectCharactersPane extends StatelessWidget {
  final Project? project;

  const ProjectCharactersPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Characters',
          description: 'Defaults for character profiles in this world.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Defaults',
          children: const [
            SettingSwitch(title: 'Show relationships', value: true),
            SettingSwitch(title: 'Show images', value: true),
            SettingSwitch(title: 'AI generation', value: false),
          ],
        ),
      ],
    );
  }
}

/// PROJECT: Locations.
class ProjectLocationsPane extends StatelessWidget {
  final Project? project;

  const ProjectLocationsPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Locations',
          description: 'Defaults for locations in this world.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Defaults',
          children: const [
            SettingSwitch(title: 'Show coordinates', value: true),
            SettingSwitch(title: 'Show hierarchy', value: true),
            SettingSwitch(title: 'Show naming rules', value: true),
          ],
        ),
      ],
    );
  }
}

/// PROJECT: Relationships.
class ProjectRelationshipsPane extends StatelessWidget {
  final Project? project;

  const ProjectRelationshipsPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Relationships',
          description: 'Relationship types and visibility are project data.',
          projectName: _projectName(project),
        ),
        SettingInfo(
          text:
              'Relationship definitions (types, categories, directionality) are configured in the relationship graph module.',
          icon: LucideIcons.gitBranch,
        ),
      ],
    );
  }
}

/// PROJECT: Research.
class ProjectResearchPane extends StatelessWidget {
  final Project? project;

  const ProjectResearchPane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Research',
          description: 'Citation and bibliography defaults.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Citations',
          children: [
            SettingDropdown<String>(
              title: 'Citation style',
              value: 'Chicago',
              items: const [
                DropdownMenuItem(value: 'Chicago', child: Text('Chicago')),
                DropdownMenuItem(value: 'MLA', child: Text('MLA')),
                DropdownMenuItem(value: 'APA', child: Text('APA')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

/// PROJECT: Proofing (project dictionary).
class ProjectProofingPane extends StatelessWidget {
  final Project? project;
  final VoidCallback? onDictionaryOpened;

  const ProjectProofingPane({super.key, this.project, this.onDictionaryOpened});

  @override
  Widget build(BuildContext context) {
    final project = this.project;
    if (project == null) return const _NoProjectPane();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Proofing',
          description:
              'Project-specific dictionary and ignore lists. These stay separate from the global dictionary.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Project Dictionary',
          children: [
            SettingTile(
              title: 'Custom dictionary',
              description: 'Manage words added to this project’s dictionary.',
              leading: const Icon(LucideIcons.book),
              control: FilledButton.tonal(
                onPressed: onDictionaryOpened,
                child: const Text('Manage Dictionary'),
              ),
            ),
          ],
        ),
        SettingSection(
          title: 'Ignore List',
          children: const [
            SettingSwitch(title: 'Ignore character names', value: true),
            SettingSwitch(title: 'Ignore location names', value: true),
            SettingSwitch(title: 'Ignore invented words', value: true),
          ],
        ),
      ],
    );
  }
}

/// PROJECT: History.
class ProjectHistoryPane extends StatelessWidget {
  final Project? project;
  final VoidCallback? onDictionaryOpened;

  const ProjectHistoryPane({super.key, this.project, this.onDictionaryOpened});

  @override
  Widget build(BuildContext context) {
    final project = this.project;
    if (project == null) return const _NoProjectPane();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Change History',
          description:
              'The project history limit controls how many versions are retained for this project.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'History',
          children: [_HistoryLimitSlider(project: project)],
        ),
        SettingInfo(
          text:
              'The project-specific history limit is authoritative. A global default applies only to newly created projects.',
          icon: Icons.history,
        ),
      ],
    );
  }
}

class _HistoryLimitSlider extends StatefulWidget {
  final Project project;

  const _HistoryLimitSlider({required this.project});

  @override
  State<_HistoryLimitSlider> createState() => _HistoryLimitSliderState();
}

class _HistoryLimitSliderState extends State<_HistoryLimitSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = (widget.project.historyLimit ?? 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SettingSlider(
      title: 'History limit',
      description: 'Keep the last ${_value.round()} versions of each item.',
      value: _value,
      min: 1,
      max: 50,
      divisions: 49,
      labelFormatter: (v) => '${v.round()}',
      onChanged: (v) => setState(() => _value = v),
      onChangeEnd: (v) {
        setState(() => _value = v);
        widget.project.historyLimit = v.round();
        widget.project.save();
      },
    );
  }
}

/// PROJECT: Project Appearance.
class ProjectAppearancePane extends StatelessWidget {
  final Project? project;

  const ProjectAppearancePane({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Project Appearance',
          description:
              'Project-specific visual identity. Application-wide theme stays global.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Identity',
          children: [
            SettingDropdown<String>(
              title: 'Project accent',
              value: 'Use global',
              items: const [
                DropdownMenuItem(
                  value: 'Use global',
                  child: Text('Use Global'),
                ),
                DropdownMenuItem(value: 'Overridden', child: Text('Override')),
              ],
              onChanged: (_) {},
            ),
            SettingSwitch(title: 'Show project icon', value: true),
          ],
        ),
        SettingInfo(
          text:
              'Where a project overrides a global appearance setting, the control is clearly marked instead of silently replacing the global value.',
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

/// PROJECT: Danger Zone.
class ProjectDangerPane extends StatelessWidget {
  final Project? project;
  final VoidCallback? onDeleteProject;

  const ProjectDangerPane({super.key, this.project, this.onDeleteProject});

  @override
  Widget build(BuildContext context) {
    final project = this.project;
    if (project == null) return const _NoProjectPane();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectHeader(
          title: 'Danger Zone',
          description:
              'Destructive operations. Every action here requires explicit confirmation.',
          projectName: _projectName(project),
        ),
        SettingSection(
          title: 'Operations',
          children: [
            SettingTile(
              title: 'Export project',
              description: 'Package the project for backup or transfer.',
              leading: const Icon(LucideIcons.download),
              control: OutlinedButton(
                onPressed: () {},
                child: const Text('Export'),
              ),
            ),
            SettingTile(
              title: 'Reset project settings',
              description:
                  'Restore this project’s settings to global defaults.',
              leading: const Icon(LucideIcons.rotateCcw),
              control: OutlinedButton(
                onPressed: () => _confirmResetSettings(context),
                child: const Text('Reset'),
              ),
            ),
            SettingTile(
              title: 'Delete project',
              description:
                  'Permanently delete this project and all its contents.',
              leading: Icon(
                LucideIcons.trash2,
                color: Theme.of(context).colorScheme.error,
              ),
              control: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => _confirmDelete(context, project),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmResetSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset project settings?'),
        content: const Text(
          'This restores project settings to their global defaults. '
          'Project data is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project settings reset to defaults.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Project project) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to permanently delete "${project.title}"? '
          'This also deletes all chapters, characters and links. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      onDeleteProject?.call();
    }
  }
}

class _NoProjectPane extends StatelessWidget {
  const _NoProjectPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Open this from within a project to configure project settings.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
