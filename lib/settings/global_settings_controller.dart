import 'package:flutter/foundation.dart';

import 'app_scale.dart';
import 'global_setting_key.dart';
import 'settings_repository.dart';

/// Controller for application-wide settings that are **not** the theme.
///
/// Theme state (theme pack, mode, accessibility) remains authoritative in
/// [ThemeNotifier] — this controller complements it with scaling, density,
/// accessibility flags, AI provider configuration, storage/backup defaults and
/// new-project history defaults. It persists through [SettingsRepository]
/// (the global `settings` Hive box) and notifies listeners so UI reacts
/// immediately to changes.
class GlobalSettingsController extends ChangeNotifier {
  GlobalSettingsController({SettingsRepository? repository})
    : _repo = repository ?? SettingsRepository();

  final SettingsRepository _repo;

  // ── Scaling ────────────────────────────────────────────────────────────

  double _interfaceScalePercent = 100;
  double _textScalePercent = 100;
  AppDensity _density = AppDensity.comfortable;

  /// Interface scale as a percentage (80–140).
  double get interfaceScalePercent => _interfaceScalePercent;

  /// Text scale as a percentage (80–160).
  double get textScalePercent => _textScalePercent;

  /// Selected density.
  AppDensity get density => _density;

  /// Resolved interface [ScaleFactor].
  ScaleFactor get interfaceFactor =>
      ScaleFactor.percent(_interfaceScalePercent, isText: false);

  /// Resolved text [ScaleFactor].
  ScaleFactor get textFactor =>
      ScaleFactor.percent(_textScalePercent, isText: true);

  /// Combined [ScaleTokens] for theme integration.
  ScaleTokens get scaleTokens => ScaleTokens(
    interfaceScale: interfaceFactor.factor,
    textScale: textFactor.factor,
    density: _density,
  );

  // ── Accessibility ──────────────────────────────────────────────────────

  bool _reduceAnimations = false;
  bool _reduceTransparency = false;
  bool _preventTextClipping = true;
  bool _autoFitLabels = true;
  bool _scaleControlsWithText = false;
  bool _autoAdaptToDensity = true;

  bool get reduceAnimations => _reduceAnimations;
  bool get reduceTransparency => _reduceTransparency;
  bool get preventTextClipping => _preventTextClipping;
  bool get autoFitLabels => _autoFitLabels;
  bool get scaleControlsWithText => _scaleControlsWithText;
  bool get autoAdaptToDensity => _autoAdaptToDensity;

  // ── Interface ──────────────────────────────────────────────────────────

  StartupPage _startupPage = StartupPage.dashboard;
  bool _showTooltips = true;
  bool _confirmDestructiveActions = true;
  bool _showStatusBar = true;

  StartupPage get startupPage => _startupPage;
  bool get showTooltips => _showTooltips;
  bool get confirmDestructiveActions => _confirmDestructiveActions;
  bool get showStatusBar => _showStatusBar;

  // ── AI Provider ────────────────────────────────────────────────────────

  bool _aiEnabled = false;
  String _aiProvider = 'Local (LM Studio / Ollama)';
  String _aiModel = '';
  String _aiEndpoint = 'http://localhost:1234/v1';
  int _aiContextLength = 4096;
  double _aiTemperature = 0.7;
  double _aiTopP = 0.9;
  int _aiMaxOutput = 2048;
  bool _aiAllowTimelineAccess = true;
  bool _aiAllowCharactersAccess = true;
  bool _aiAllowManuscriptAccess = false;

  bool get aiEnabled => _aiEnabled;
  String get aiProvider => _aiProvider;
  String get aiModel => _aiModel;
  String get aiEndpoint => _aiEndpoint;
  int get aiContextLength => _aiContextLength;
  double get aiTemperature => _aiTemperature;
  double get aiTopP => _aiTopP;
  int get aiMaxOutput => _aiMaxOutput;
  bool get aiAllowTimelineAccess => _aiAllowTimelineAccess;
  bool get aiAllowCharactersAccess => _aiAllowCharactersAccess;
  bool get aiAllowManuscriptAccess => _aiAllowManuscriptAccess;

  // ── Storage / Backup ───────────────────────────────────────────────────

  String _defaultProjectLocation = '';
  String _exportLocation = '';
  bool _autoBackupEnabled = false;
  int _backupIntervalDays = 7;
  int _backupRetentionCount = 5;
  bool _backupIncludeMedia = true;

  String get defaultProjectLocation => _defaultProjectLocation;
  String get exportLocation => _exportLocation;
  bool get autoBackupEnabled => _autoBackupEnabled;
  int get backupIntervalDays => _backupIntervalDays;
  int get backupRetentionCount => _backupRetentionCount;
  bool get backupIncludeMedia => _backupIncludeMedia;

  // ── History ────────────────────────────────────────────────────────────

  int _defaultHistoryLimit = 10;

  /// Default history limit applied to newly created projects.
  int get defaultHistoryLimit => _defaultHistoryLimit;

  /// Loads persisted values into memory. Called once at startup.
  Future<void> load() async {
    _interfaceScalePercent = _repo.getDouble(
      GlobalSettingKey.interfaceScale,
      100,
    );
    _textScalePercent = _repo.getDouble(GlobalSettingKey.textScale, 100);
    _density = _repo.getEnum(
      GlobalSettingKey.density,
      AppDensity.comfortable,
      AppDensity.values,
    );

    _reduceAnimations = _repo.get(GlobalSettingKey.reduceAnimations, false);
    _reduceTransparency = _repo.get(GlobalSettingKey.reduceTransparency, false);
    _preventTextClipping = _repo.get(
      GlobalSettingKey.preventTextClipping,
      true,
    );
    _autoFitLabels = _repo.get(GlobalSettingKey.autoFitLabels, true);
    _scaleControlsWithText = _repo.get(
      GlobalSettingKey.scaleControlsWithText,
      false,
    );
    _autoAdaptToDensity = _repo.get(GlobalSettingKey.autoAdaptToDensity, true);

    _startupPage = _repo.getEnum(
      GlobalSettingKey.startupPage,
      StartupPage.dashboard,
      StartupPage.values,
    );
    _showTooltips = _repo.get(GlobalSettingKey.showTooltips, true);
    _confirmDestructiveActions = _repo.get(
      GlobalSettingKey.confirmDestructiveActions,
      true,
    );
    _showStatusBar = _repo.get(GlobalSettingKey.showStatusBar, true);

    _aiEnabled = _repo.get(GlobalSettingKey.aiEnabled, false);
    _aiProvider = _repo.get(
      GlobalSettingKey.aiProvider,
      'Local (LM Studio / Ollama)',
    );
    _aiModel = _repo.get(GlobalSettingKey.aiModel, '');
    _aiEndpoint = _repo.get(
      GlobalSettingKey.aiEndpoint,
      'http://localhost:1234/v1',
    );
    _aiContextLength = _repo.get(GlobalSettingKey.aiContextLength, 4096);
    _aiTemperature = _repo.getDouble(GlobalSettingKey.aiTemperature, 0.7);
    _aiTopP = _repo.getDouble(GlobalSettingKey.aiTopP, 0.9);
    _aiMaxOutput = _repo.get(GlobalSettingKey.aiMaxOutput, 2048);
    _aiAllowTimelineAccess = _repo.get(
      GlobalSettingKey.aiAllowTimelineAccess,
      true,
    );
    _aiAllowCharactersAccess = _repo.get(
      GlobalSettingKey.aiAllowCharactersAccess,
      true,
    );
    _aiAllowManuscriptAccess = _repo.get(
      GlobalSettingKey.aiAllowManuscriptAccess,
      false,
    );

    _defaultProjectLocation = _repo.get(
      GlobalSettingKey.defaultProjectLocation,
      '',
    );
    _exportLocation = _repo.get(GlobalSettingKey.exportLocation, '');
    _autoBackupEnabled = _repo.get(GlobalSettingKey.autoBackupEnabled, false);
    _backupIntervalDays = _repo.get(GlobalSettingKey.backupIntervalDays, 7);
    _backupRetentionCount = _repo.get(GlobalSettingKey.backupRetentionCount, 5);
    _backupIncludeMedia = _repo.get(GlobalSettingKey.backupIncludeMedia, true);

    _defaultHistoryLimit = _repo.get(GlobalSettingKey.defaultHistoryLimit, 10);

    notifyListeners();
  }

  // ── Setters (persist immediately) ──────────────────────────────────────

  Future<void> setInterfaceScale(double percent) async {
    _interfaceScalePercent = percent;
    await _repo.set(GlobalSettingKey.interfaceScale, percent);
    notifyListeners();
  }

  Future<void> setTextScale(double percent) async {
    _textScalePercent = percent;
    await _repo.set(GlobalSettingKey.textScale, percent);
    notifyListeners();
  }

  Future<void> setDensity(AppDensity density) async {
    _density = density;
    await _repo.set(GlobalSettingKey.density, density.key);
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    await _repo.set(GlobalSettingKey.reduceAnimations, value);
    notifyListeners();
  }

  Future<void> setReduceTransparency(bool value) async {
    _reduceTransparency = value;
    await _repo.set(GlobalSettingKey.reduceTransparency, value);
    notifyListeners();
  }

  Future<void> setPreventTextClipping(bool value) async {
    _preventTextClipping = value;
    await _repo.set(GlobalSettingKey.preventTextClipping, value);
    notifyListeners();
  }

  Future<void> setAutoFitLabels(bool value) async {
    _autoFitLabels = value;
    await _repo.set(GlobalSettingKey.autoFitLabels, value);
    notifyListeners();
  }

  Future<void> setScaleControlsWithText(bool value) async {
    _scaleControlsWithText = value;
    await _repo.set(GlobalSettingKey.scaleControlsWithText, value);
    notifyListeners();
  }

  Future<void> setAutoAdaptToDensity(bool value) async {
    _autoAdaptToDensity = value;
    await _repo.set(GlobalSettingKey.autoAdaptToDensity, value);
    notifyListeners();
  }

  Future<void> setStartupPage(StartupPage page) async {
    _startupPage = page;
    await _repo.set(GlobalSettingKey.startupPage, page.key);
    notifyListeners();
  }

  Future<void> setShowTooltips(bool value) async {
    _showTooltips = value;
    await _repo.set(GlobalSettingKey.showTooltips, value);
    notifyListeners();
  }

  Future<void> setConfirmDestructiveActions(bool value) async {
    _confirmDestructiveActions = value;
    await _repo.set(GlobalSettingKey.confirmDestructiveActions, value);
    notifyListeners();
  }

  Future<void> setShowStatusBar(bool value) async {
    _showStatusBar = value;
    await _repo.set(GlobalSettingKey.showStatusBar, value);
    notifyListeners();
  }

  Future<void> setAiEnabled(bool value) async {
    _aiEnabled = value;
    await _repo.set(GlobalSettingKey.aiEnabled, value);
    notifyListeners();
  }

  Future<void> setAiProvider(String value) async {
    _aiProvider = value;
    await _repo.set(GlobalSettingKey.aiProvider, value);
    notifyListeners();
  }

  Future<void> setAiModel(String value) async {
    _aiModel = value;
    await _repo.set(GlobalSettingKey.aiModel, value);
    notifyListeners();
  }

  Future<void> setAiEndpoint(String value) async {
    _aiEndpoint = value;
    await _repo.set(GlobalSettingKey.aiEndpoint, value);
    notifyListeners();
  }

  Future<void> setAiContextLength(int value) async {
    _aiContextLength = value;
    await _repo.set(GlobalSettingKey.aiContextLength, value);
    notifyListeners();
  }

  Future<void> setAiTemperature(double value) async {
    _aiTemperature = value;
    await _repo.set(GlobalSettingKey.aiTemperature, value);
    notifyListeners();
  }

  Future<void> setAiTopP(double value) async {
    _aiTopP = value;
    await _repo.set(GlobalSettingKey.aiTopP, value);
    notifyListeners();
  }

  Future<void> setAiMaxOutput(int value) async {
    _aiMaxOutput = value;
    await _repo.set(GlobalSettingKey.aiMaxOutput, value);
    notifyListeners();
  }

  Future<void> setAiAllowTimelineAccess(bool value) async {
    _aiAllowTimelineAccess = value;
    await _repo.set(GlobalSettingKey.aiAllowTimelineAccess, value);
    notifyListeners();
  }

  Future<void> setAiAllowCharactersAccess(bool value) async {
    _aiAllowCharactersAccess = value;
    await _repo.set(GlobalSettingKey.aiAllowCharactersAccess, value);
    notifyListeners();
  }

  Future<void> setAiAllowManuscriptAccess(bool value) async {
    _aiAllowManuscriptAccess = value;
    await _repo.set(GlobalSettingKey.aiAllowManuscriptAccess, value);
    notifyListeners();
  }

  Future<void> setDefaultProjectLocation(String value) async {
    _defaultProjectLocation = value;
    await _repo.set(GlobalSettingKey.defaultProjectLocation, value);
    notifyListeners();
  }

  Future<void> setExportLocation(String value) async {
    _exportLocation = value;
    await _repo.set(GlobalSettingKey.exportLocation, value);
    notifyListeners();
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    _autoBackupEnabled = value;
    await _repo.set(GlobalSettingKey.autoBackupEnabled, value);
    notifyListeners();
  }

  Future<void> setBackupIntervalDays(int value) async {
    _backupIntervalDays = value;
    await _repo.set(GlobalSettingKey.backupIntervalDays, value);
    notifyListeners();
  }

  Future<void> setBackupRetentionCount(int value) async {
    _backupRetentionCount = value;
    await _repo.set(GlobalSettingKey.backupRetentionCount, value);
    notifyListeners();
  }

  Future<void> setBackupIncludeMedia(bool value) async {
    _backupIncludeMedia = value;
    await _repo.set(GlobalSettingKey.backupIncludeMedia, value);
    notifyListeners();
  }

  Future<void> setDefaultHistoryLimit(int value) async {
    _defaultHistoryLimit = value;
    await _repo.set(GlobalSettingKey.defaultHistoryLimit, value);
    notifyListeners();
  }

  /// Resets adaptive/accessibility flags to defaults (used by an explicit
  /// "Reset to Defaults" action, never invoked automatically).
  Future<void> resetAccessibilityDefaults() async {
    await setInterfaceScale(100);
    await setTextScale(100);
    await setDensity(AppDensity.comfortable);
    await setReduceAnimations(false);
    await setReduceTransparency(false);
    await setPreventTextClipping(true);
    await setAutoFitLabels(true);
    await setScaleControlsWithText(false);
    await setAutoAdaptToDensity(true);
  }
}
