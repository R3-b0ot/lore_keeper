import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_manager.dart';

import 'global_setting_key.dart';

/// Types accepted for persisted boolean/int/double/string settings.
typedef SettingValue = Object;

/// Thin persistence layer over the global `settings` Hive box.
///
/// The UI never touches `Hive.box('settings')` directly; it goes through
/// [GlobalSettingsController], which delegates reads/writes here. This keeps
/// Hive access isolated to a single repository and gives us a single place to
/// evolve or migrate the on-disk key format.
///
/// Existing theme keys are deliberately preserved (see [GlobalSettingKey]).
class SettingsRepository {
  SettingsRepository({Box? box}) : _boxOverride = box;

  final Box? _boxOverride;

  /// Lazily resolves the global settings box.
  Box get _box => _boxOverride ?? DatabaseManager.instance.settings;

  /// Reads a setting by its typed key, returning [fallback] when absent.
  T get<T>(GlobalSettingKey key, T fallback) {
    final raw = _box.get(key.key);
    if (raw is T) return raw;
    return fallback;
  }

  /// Reads a setting as a double, coercing int values.
  double getDouble(GlobalSettingKey key, double fallback) {
    final raw = _box.get(key.key);
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is num) return raw.toDouble();
    return fallback;
  }

  /// Reads an enum by its string key, falling back to [fallback].
  ///
  /// The [values] list must be the enum's `.values`. Unknown or absent values
  /// resolve to [fallback].
  E getEnum<E extends Enum>(GlobalSettingKey key, E fallback, List<E> values) {
    final raw = _box.get(key.key);
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    }
    return fallback;
  }

  /// Persists [value] under the given [key] immediately.
  Future<void> set(GlobalSettingKey key, SettingValue value) =>
      _box.put(key.key, value);

  /// Removes the persisted value for [key], restoring defaults.
  Future<void> remove(GlobalSettingKey key) async {
    if (_box.containsKey(key.key)) {
      await _box.delete(key.key);
    }
  }
}
