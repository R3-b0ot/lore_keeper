/// Typed identifiers for every persisted global application setting.
///
/// Centralizing the keys here avoids scattering raw string literals (and the
/// associated Hive box keys) throughout the widget layer. The string value is
/// the exact key used inside the `settings` Hive box so persisted values
/// remain stable across renames of the enum member.
///
/// Backward compatibility is preserved: existing keys (`themeMode`,
/// `themePack`, `accessibilityRating`) keep their historical names.
enum GlobalSettingKey {
  // ── Theme (managed by ThemeNotifier, listed for completeness) ──────────
  themePack('themePack'),
  themeMode('themeMode'),
  accessibilityRating('accessibilityRating'),

  // ── Appearance / Scaling ───────────────────────────────────────────────
  interfaceScale('interfaceScale'),
  textScale('textScale'),
  density('uiDensity'),
  highContrast('highContrast'),
  reduceAnimations('reduceAnimations'),
  reduceTransparency('reduceTransparency'),
  preventTextClipping('preventTextClipping'),
  autoFitLabels('autoFitLabels'),
  scaleControlsWithText('scaleControlsWithText'),
  autoAdaptToDensity('autoAdaptToDensity'),

  // ── Interface / Startup ────────────────────────────────────────────────
  startupPage('startupPage'),
  showTooltips('showTooltips'),
  confirmDestructiveActions('confirmDestructiveActions'),
  showStatusBar('showStatusBar'),

  // ── AI Provider ────────────────────────────────────────────────────────
  aiEnabled('aiEnabled'),
  aiProvider('aiProvider'),
  aiModel('aiModel'),
  aiEndpoint('aiEndpoint'),
  aiContextLength('aiContextLength'),
  aiTemperature('aiTemperature'),
  aiTopP('aiTopP'),
  aiMaxOutput('aiMaxOutput'),
  aiAllowTimelineAccess('aiAllowTimelineAccess'),
  aiAllowCharactersAccess('aiAllowCharactersAccess'),
  aiAllowManuscriptAccess('aiAllowManuscriptAccess'),

  // ── Storage / Backup ───────────────────────────────────────────────────
  defaultProjectLocation('defaultProjectLocation'),
  exportLocation('exportLocation'),
  autoBackupEnabled('autoBackupEnabled'),
  backupIntervalDays('backupIntervalDays'),
  backupRetentionCount('backupRetentionCount'),
  backupIncludeMedia('backupIncludeMedia'),

  // ── History (global default for new projects) ─────────────────────────
  defaultHistoryLimit('defaultHistoryLimit');

  /// The raw Hive box key for this setting.
  final String key;

  const GlobalSettingKey(this.key);
}

/// Density options for the interface scaling system.
enum AppDensity {
  compact('compact'),
  comfortable('comfortable'),
  spacious('spacious');

  const AppDensity(this.key);

  /// Persisted string representation.
  final String key;

  /// Human-readable label.
  String get label {
    switch (this) {
      case AppDensity.compact:
        return 'Compact';
      case AppDensity.comfortable:
        return 'Comfortable';
      case AppDensity.spacious:
        return 'Spacious';
    }
  }
}

/// Starting page shown when the application launches.
enum StartupPage {
  dashboard('dashboard'),
  lastProject('lastProject');

  const StartupPage(this.key);
  final String key;
}
