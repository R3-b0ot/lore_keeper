import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import 'package:lore_keeper/database/ai/ai_provider_factory.dart';
import 'package:lore_keeper/database/ai/device_ai/device_ai_discovery.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:lore_keeper/settings/global_settings_controller.dart';
import 'package:lore_keeper/settings/global_setting_key.dart';
import 'package:lore_keeper/settings/widgets/settings_widgets.dart';

/// Shared helper building a typed pane header.
Widget _paneHeader({
  required BuildContext context,
  required bool isProject,
  required String title,
  required String description,
  String? projectName,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingScopeBadge(isProject: isProject, projectName: projectName),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 13, color: _muted(context)),
        ),
      ],
    ),
  );
}

Color _muted(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

/// GLOBAL: Appearance & Scaling.
class GlobalAppearancePane extends StatelessWidget {
  final Widget? projectWidget;

  const GlobalAppearancePane({super.key, this.projectWidget});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final settings = context.watch<GlobalSettingsController>();
    final packNames = <String, String>{
      'minimal': 'Minimal',
      'dracula': 'Dracula',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Appearance & Scaling',
          description:
              'Manage how Lore Keeper looks and scales across all your projects.',
        ),
        // Theme
        SettingSection(
          title: 'Theme',
          children: [
            SettingDropdown<String>(
              title: 'Theme Pack',
              description: 'The colour aesthetic used across the application.',
              value: themeNotifier.themePack,
              items: [
                for (final entry in packNames.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) {
                if (v != null) themeNotifier.setThemePack(v);
              },
            ),
            SettingSegmentedControl<ThemeMode>(
              title: 'Theme Mode',
              description: 'Match the system, or force light or dark.',
              value: themeNotifier.themeMode,
              options: const [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ],
              labelOf: (mode) => switch (mode) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              iconOf: (mode) => switch (mode) {
                ThemeMode.system => Icons.brightness_auto,
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
              },
              onChanged: themeNotifier.setTheme,
            ),
            if (themeNotifier.themePack == 'minimal')
              SettingSegmentedControl<AccessibilityRating>(
                title: 'Contrast Level',
                description: 'Standard (AA) or enhanced (AAA) contrast.',
                value: themeNotifier.accessibilityRating,
                options: const [
                  AccessibilityRating.aa,
                  AccessibilityRating.aaa,
                ],
                labelOf: (r) => switch (r) {
                  AccessibilityRating.aa => 'Standard',
                  AccessibilityRating.aaa => 'High Contrast',
                },
                onChanged: themeNotifier.setAccessibilityRating,
              ),
          ],
        ),
        // Interface Scaling
        SettingSection(
          title: 'Interface Scaling',
          children: [
            SettingSlider(
              title: 'Interface Scale',
              description: 'Scales UI dimensions, spacing, icons and controls.',
              value: settings.interfaceScalePercent,
              min: 80,
              max: 140,
              divisions: 60,
              labelFormatter: (v) => '${v.round()}%',
              onChanged: settings.setInterfaceScale,
            ),
            SettingSlider(
              title: 'Text Scale',
              description: 'Scales typography independently of the interface.',
              value: settings.textScalePercent,
              min: 80,
              max: 160,
              divisions: 80,
              labelFormatter: (v) => '${v.round()}%',
              onChanged: settings.setTextScale,
            ),
            SettingDropdown<AppDensity>(
              title: 'Density',
              description: 'Compact, comfortable or spacious control spacing.',
              value: settings.density,
              items: [
                for (final d in AppDensity.values)
                  DropdownMenuItem(value: d, child: Text(d.label)),
              ],
              onChanged: (v) {
                if (v != null) settings.setDensity(v);
              },
            ),
            SettingSwitch(
              title: 'Automatically adapt to display density',
              value: settings.autoAdaptToDensity,
              onChanged: settings.setAutoAdaptToDensity,
            ),
          ],
        ),
        // Accessibility
        SettingSection(
          title: 'Accessibility',
          description:
              'These controls drive real animation and rendering behaviour.',
          children: [
            SettingSwitch(
              title: 'Reduce Animations',
              description: 'Minimises motion across the interface.',
              value: settings.reduceAnimations,
              onChanged: settings.setReduceAnimations,
              tooltip:
                  'When enabled, animated transitions are shortened or removed for users sensitive to motion.',
            ),
            SettingSwitch(
              title: 'Reduce Transparency',
              description: 'Replaces translucent surfaces with opaque ones.',
              value: settings.reduceTransparency,
              onChanged: settings.setReduceTransparency,
            ),
            SettingSwitch(
              title: 'Prevent text clipping',
              description: 'Wraps or reflows labels instead of truncating.',
              value: settings.preventTextClipping,
              onChanged: settings.setPreventTextClipping,
            ),
            SettingSwitch(
              title: 'Auto-fit labels',
              description: 'Adapts label sizing to the available width.',
              value: settings.autoFitLabels,
              onChanged: settings.setAutoFitLabels,
            ),
            SettingSwitch(
              title: 'Scale controls with text',
              description: 'Sizes controls in proportion to text scale.',
              value: settings.scaleControlsWithText,
              onChanged: settings.setScaleControlsWithText,
            ),
          ],
        ),
        if (projectWidget != null) ...[
          const SizedBox(height: 8),
          projectWidget!,
        ],
      ],
    );
  }
}

/// GLOBAL: Interface & Startup.
class GlobalInterfacePane extends StatelessWidget {
  const GlobalInterfacePane({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Interface',
          description:
              'Startup behaviour, navigation and interaction defaults.',
        ),
        SettingSection(
          title: 'Startup & Window',
          children: [
            SettingDropdown<StartupPage>(
              title: 'Startup page',
              description: 'Which screen to show when Lore Keeper launches.',
              value: settings.startupPage,
              items: const [
                DropdownMenuItem(
                  value: StartupPage.dashboard,
                  child: Text('Dashboard'),
                ),
                DropdownMenuItem(
                  value: StartupPage.lastProject,
                  child: Text('Last opened project'),
                ),
              ],
              onChanged: (v) {
                if (v != null) settings.setStartupPage(v);
              },
            ),
            SettingSwitch(
              title: 'Show status bar',
              value: settings.showStatusBar,
              onChanged: settings.setShowStatusBar,
            ),
          ],
        ),
        SettingSection(
          title: 'Navigation & Feedback',
          children: [
            SettingSwitch(
              title: 'Show tooltips',
              description: 'Contextual hints on hover.',
              value: settings.showTooltips,
              onChanged: settings.setShowTooltips,
            ),
            SettingSwitch(
              title: 'Confirm destructive actions',
              description:
                  'Requires confirmation before deleting or overwriting.',
              value: settings.confirmDestructiveActions,
              onChanged: settings.setConfirmDestructiveActions,
            ),
          ],
        ),
      ],
    );
  }
}

/// GLOBAL: Editor Defaults.
class GlobalEditorPane extends StatelessWidget {
  const GlobalEditorPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Editor Defaults',
          description:
              'Default formatting and typing behaviour for new manuscripts.',
        ),
        SettingSection(
          title: 'Typography',
          children: <Widget>[
            SettingTextField(
              title: 'Default Font',
              description: 'Applied to new documents (inherited by projects).',
              hintText: 'Inter',
            ),
          ],
        ),
        SettingInfo(
          text:
              'Project-specific editor overrides inherit these global defaults unless explicitly overridden.',
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

/// GLOBAL: Proofing.
class GlobalProofingPane extends StatelessWidget {
  const GlobalProofingPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Proofing',
          description: 'Spell check, grammar and style defaults.',
        ),
        SettingSection(
          title: 'Checking',
          children: [
            SettingSwitch(title: 'Spell check', value: true),
            SettingSwitch(title: 'Grammar checking', value: true),
            SettingSwitch(title: 'Style suggestions', value: false),
          ],
        ),
        SettingSection(
          title: 'Customisation',
          children: [
            SettingSwitch(title: 'Ignore proper nouns', value: true),
            SettingSwitch(title: 'Ignore numbers', value: false),
            SettingSwitch(title: 'Ignore capitalised words', value: true),
          ],
        ),
        SettingInfo(
          text: 'The project dictionary and global dictionary remain separate.',
          icon: Icons.abc,
        ),
      ],
    );
  }
}

/// GLOBAL: AI Provider.
class GlobalAiPane extends HookWidget {
  const GlobalAiPane({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsController>();

    // Fresh state for the device-AI discovery flow.
    final scanning = useState(false);
    final endpoints = useState<List<DeviceAiEndpoint>>(const []);
    final selectedEndpoint = useState<DeviceAiEndpoint?>(null);
    final scanNotice = useState<String?>(null);

    Future<void> runDiscovery() async {
      scanning.value = true;
      scanNotice.value = null;
      try {
        final found = await DeviceAiDiscovery().discover();
        endpoints.value = found;
        if (found.isEmpty) {
          scanNotice.value =
              'No local AI engine is responding. Install Windows AI Foundry '
              '(`winget install Microsoft.FoundryLocal`) and run a model, or '
              'start LM Studio / Ollama, then scan again.';
          return;
        }
        final first = found.first;
        selectedEndpoint.value = first;
        await settings.setAiProvider(AiProviders.deviceFoundry);
        await settings.setAiEndpoint(first.baseUrl);
        if (first.models.isNotEmpty) {
          await settings.setAiModel(first.models.first.id);
        }
        scanNotice.value =
            'Connected to ${first.providerHint ?? first.baseUrl}.';
      } catch (e) {
        scanNotice.value = 'Discovery failed: $e';
      } finally {
        scanning.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'AI Provider Settings',
          description:
              'Configure LLM connections for lore generation and assistance.',
        ),
        SettingSection(
          title: 'Connection',
          children: [
            SettingSwitch(
              title: 'Enable AI Features',
              description: 'Master switch for all AI integrations.',
              value: settings.aiEnabled,
              onChanged: settings.setAiEnabled,
            ),
            SettingDropdown<String>(
              title: 'Provider Type',
              value: settings.aiProvider,
              items: const [
                DropdownMenuItem(
                  value: AiProviders.onDevice,
                  child: Text(AiProviders.onDevice),
                ),
                DropdownMenuItem(
                  value: AiProviders.local,
                  child: Text(AiProviders.local),
                ),
                DropdownMenuItem(
                  value: AiProviders.deviceFoundry,
                  child: Text(AiProviders.deviceFoundry),
                ),
                DropdownMenuItem(
                  value: AiProviders.openAi,
                  child: Text(AiProviders.openAi),
                ),
                DropdownMenuItem(
                  value: AiProviders.anthropic,
                  child: Text(AiProviders.anthropic),
                ),
              ],
              onChanged: (v) {
                if (v != null) settings.setAiProvider(v);
              },
            ),
            if (settings.aiProvider == AiProviders.onDevice)
              SettingInfo(
                text:
                    'No server or endpoint needed. A ~70 MB model downloads '
                    'on first AI use, then runs locally on this device via '
                    'llama.cpp — fully offline afterwards.',
                icon: Icons.download_for_offline_outlined,
              )
            else ...[
              SettingTextField(
                title: 'Local Endpoint URL',
                description: 'Where the local model server listens.',
                controller: null,
                initialValue: settings.aiEndpoint,
                onChanged: settings.setAiEndpoint,
                monospace: true,
              ),
              SettingTextField(
                title: 'Model',
                description: 'Model identifier (e.g. nomic-embed-text).',
                initialValue: settings.aiModel,
                onChanged: settings.setAiModel,
                monospace: true,
              ),
            ],
          ],
        ),
        SettingSection(
          title: 'Device AI (Windows AI Foundry)',
          description:
              'Use the model runtime built into your device. Windows AI '
              'Foundry serves an OpenAI-compatible endpoint on localhost; '
              'discovery finds it automatically.',
          children: [
            SettingInfo(
              text:
                  'Scanning probes the loopback ports of known local engines '
                  '(Foundry Local, LM Studio, Ollama) for an OpenAI-compatible '
                  '`/v1/models` endpoint.',
              icon: Icons.memory,
            ),
            SettingTile(
              title: 'Detect device AI',
              description: 'Auto-find and configure the local endpoint.',
              control: scanning.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: runDiscovery,
                      icon: const Icon(Icons.radar, size: 18),
                      label: const Text('Scan'),
                    ),
            ),
            if (scanNotice.value != null)
              SettingInfo(
                text: scanNotice.value!,
                icon: endpoints.value.isEmpty
                    ? Icons.info_outline
                    : Icons.check_circle_outline,
                warning: endpoints.value.isEmpty,
              ),
            if (selectedEndpoint.value != null) ...[
              SettingDropdown<DeviceAiEndpoint>(
                title: 'Endpoint',
                description: 'Capabilities detected on this device.',
                value: selectedEndpoint.value!,
                items: [
                  for (final endpoint in endpoints.value)
                    DropdownMenuItem(
                      value: endpoint,
                      child: Text(
                        '${endpoint.baseUrl}'
                        '${endpoint.providerHint == null ? '' : ' — ${endpoint.providerHint}'}',
                      ),
                    ),
                ],
                onChanged: (endpoint) async {
                  if (endpoint == null) return;
                  selectedEndpoint.value = endpoint;
                  await settings.setAiProvider(AiProviders.deviceFoundry);
                  await settings.setAiEndpoint(endpoint.baseUrl);
                  if (endpoint.models.isNotEmpty) {
                    await settings.setAiModel(endpoint.models.first.id);
                  }
                },
              ),
              SettingDropdown<String>(
                title: 'Device Model',
                description: 'Which model the local runtime exposes.',
                value: settings.aiModel,
                items: [
                  for (final modelId in selectedEndpoint.value!.modelIds)
                    DropdownMenuItem(value: modelId, child: Text(modelId)),
                ],
                onChanged: (v) {
                  if (v != null) settings.setAiModel(v);
                },
              ),
            ],
          ],
        ),
        SettingSection(
          title: 'Parameters',
          children: [
            SettingSlider(
              title: 'Temperature',
              value: settings.aiTemperature,
              min: 0,
              max: 2,
              divisions: 40,
              labelFormatter: (v) => v.toStringAsFixed(2),
              onChanged: settings.setAiTemperature,
            ),
            SettingSlider(
              title: 'Top P',
              value: settings.aiTopP,
              min: 0,
              max: 1,
              divisions: 20,
              labelFormatter: (v) => v.toStringAsFixed(2),
              onChanged: settings.setAiTopP,
            ),
            SettingSlider(
              title: 'Context Length',
              value: settings.aiContextLength.toDouble(),
              min: 512,
              max: 32768,
              divisions: 60,
              labelFormatter: (v) => v.round().toString(),
              onChanged: (v) => settings.setAiContextLength(v.round()),
            ),
            SettingSlider(
              title: 'Maximum Output',
              value: settings.aiMaxOutput.toDouble(),
              min: 256,
              max: 8192,
              divisions: 60,
              labelFormatter: (v) => v.round().toString(),
              onChanged: (v) => settings.setAiMaxOutput(v.round()),
            ),
          ],
        ),
        SettingSection(
          title: 'Privacy Permissions',
          description: 'Control what AI may access from your projects.',
          children: [
            SettingSwitch(
              title: 'Allow AI to access project timeline',
              value: settings.aiAllowTimelineAccess,
              onChanged: settings.setAiAllowTimelineAccess,
            ),
            SettingSwitch(
              title: 'Allow AI to access characters',
              value: settings.aiAllowCharactersAccess,
              onChanged: settings.setAiAllowCharactersAccess,
            ),
            SettingSwitch(
              title: 'Allow AI to access current manuscript',
              value: settings.aiAllowManuscriptAccess,
              onChanged: settings.setAiAllowManuscriptAccess,
            ),
          ],
        ),
      ],
    );
  }
}

/// GLOBAL: Storage.
class GlobalStoragePane extends StatelessWidget {
  const GlobalStoragePane({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Storage',
          description: 'Default locations for projects and exported files.',
        ),
        SettingSection(
          title: 'Locations',
          children: [
            SettingTextField(
              title: 'Default project location',
              description: 'Folder where new projects are created.',
              initialValue: settings.defaultProjectLocation,
              onChanged: settings.setDefaultProjectLocation,
              monospace: true,
            ),
            SettingTextField(
              title: 'Export location',
              description: 'Default folder for exports.',
              initialValue: settings.exportLocation,
              onChanged: settings.setExportLocation,
              monospace: true,
            ),
          ],
        ),
        SettingInfo(
          text:
              'Database maintenance and cache cleanup are performed automatically; no action required here.',
          icon: Icons.storage,
        ),
      ],
    );
  }
}

/// GLOBAL: Backup.
class GlobalBackupPane extends StatelessWidget {
  const GlobalBackupPane({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Backup',
          description: 'Automatic backup schedule and retention.',
        ),
        SettingSection(
          title: 'Schedule',
          children: [
            SettingSwitch(
              title: 'Automatic backups',
              description:
                  'A scheduled backup engine will use these settings once enabled.',
              value: settings.autoBackupEnabled,
              onChanged: settings.setAutoBackupEnabled,
            ),
            SettingSlider(
              title: 'Backup interval (days)',
              value: settings.backupIntervalDays.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              labelFormatter: (v) => '${v.round()} days',
              onChanged: (v) => settings.setBackupIntervalDays(v.round()),
            ),
            SettingSlider(
              title: 'Backup retention',
              value: settings.backupRetentionCount.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              labelFormatter: (v) => '${v.round()} copies',
              onChanged: (v) => settings.setBackupRetentionCount(v.round()),
            ),
            SettingSwitch(
              title: 'Include media in backups',
              value: settings.backupIncludeMedia,
              onChanged: settings.setBackupIncludeMedia,
            ),
          ],
        ),
      ],
    );
  }
}

/// GLOBAL: Import / Export.
class GlobalImportExportPane extends StatelessWidget {
  const GlobalImportExportPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Import / Export',
          description:
              'Defaults applied when exporting projects and manuscripts.',
        ),
        SettingSection(
          title: 'Defaults',
          children: [
            SettingDropdown<String>(
              title: 'Default export format',
              value: 'Markdown',
              items: const [
                DropdownMenuItem(value: 'Markdown', child: Text('Markdown')),
                DropdownMenuItem(value: 'DOCX', child: Text('DOCX')),
                DropdownMenuItem(value: 'PDF', child: Text('PDF')),
              ],
              onChanged: (_) {},
            ),
            SettingDropdown<String>(
              title: 'File naming convention',
              value: 'Title',
              items: const [
                DropdownMenuItem(value: 'Title', child: Text('Project title')),
                DropdownMenuItem(value: 'Date', child: Text('Date + title')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        SettingSection(
          title: 'Include',
          children: const [
            SettingSwitch(title: 'Include references', value: true),
            SettingSwitch(title: 'Include images', value: true),
            SettingSwitch(title: 'Include notes', value: true),
            SettingSwitch(title: 'Preserve formatting', value: true),
          ],
        ),
      ],
    );
  }
}

/// GLOBAL: Keyboard Shortcuts.
class GlobalShortcutsPane extends StatelessWidget {
  const GlobalShortcutsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'Keyboard Shortcuts',
          description: 'Customise and discover available shortcuts.',
        ),
        SettingSection(
          title: 'Shortcuts',
          children: [
            SettingInfo(
              text:
                  'A full shortcut editor is planned. Existing in-app shortcuts continue to work.',
              icon: Icons.keyboard,
            ),
          ],
        ),
        SettingSegmentedControl<String>(
          title: 'Shortcut category',
          value: 'All',
          options: const ['All', 'Navigation', 'Editing', 'Project'],
          labelOf: (v) => v,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

/// GLOBAL: About.
class GlobalAboutPane extends StatelessWidget {
  const GlobalAboutPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paneHeader(
          context: context,
          isProject: false,
          title: 'About Lore Keeper',
          description: 'Version, build information and credits.',
        ),
        SettingSection(
          title: 'Application',
          children: [
            SettingTile(title: 'Version', control: const Text('1.0.0')),
            SettingTile(title: 'Build', control: const Text('stable')),
            SettingTile(
              title: 'Licenses',
              control: TextButton(
                onPressed: () => showLicensePage(context: context),
                child: const Text('View Licenses'),
              ),
            ),
          ],
        ),
        SettingSection(
          title: 'Credits',
          children: const [
            SettingTile(
              title: 'flutter_quill',
              description: 'Rich text editing.',
            ),
            SettingTile(
              title: 'language_tool',
              description: 'Grammar and style checking.',
            ),
            SettingTile(
              title: 'Hive',
              description: 'Fast local database storage.',
            ),
          ],
        ),
      ],
    );
  }
}
