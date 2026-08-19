import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/foundation.dart' show immutable;

import 'accessibility_rating.dart';
import 'theme_color_tokens.dart';
import 'theme_font_tokens.dart';

/// Immutable metadata for a theme pack.
@immutable
class ThemePackMetadata {
  /// Unique identifier for this pack (e.g., 'dracula', 'minimal').
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Short description of the theme's aesthetics.
  final String description;

  /// Theme creator or authority.
  final String author;

  /// Theme pack semantic version.
  final String version;

  const ThemePackMetadata({
    required this.id,
    required this.displayName,
    required this.description,
    required this.author,
    required this.version,
  });
}

/// A dual dark/light theme pack contract.
///
/// Every [ThemePack] defines both dark and light color tokens, font family tokens,
/// and can construct a full [ThemeData] instance given the brightness and accessibility rating.
abstract class ThemePack {
  /// Metadata identifying this theme pack.
  ThemePackMetadata get metadata;

  /// Color tokens for dark mode.
  ThemeColorTokens get darkColors;

  /// Color tokens for light mode.
  ThemeColorTokens get lightColors;

  /// Font family tokens exposed for UI and custom pack rendering.
  ThemeFontTokens get fonts;

  /// Build full [ThemeData] for the given mode and accessibility level.
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  });
}

/// Registry for built-in and runtime-loaded dual theme packs.
class ThemeRegistry {
  ThemeRegistry._internal();

  /// Shared global instance of [ThemeRegistry].
  static final ThemeRegistry instance = ThemeRegistry._internal();

  /// Factory constructor returning the singleton instance.
  factory ThemeRegistry() => instance;

  final Map<String, ThemePack> _packsById = {};

  /// Registers a [ThemePack]. Overwrites if the ID is already registered.
  void register(ThemePack pack) {
    _packsById[pack.metadata.id] = pack;
  }

  /// Retrieves a [ThemePack] by ID, falling back to 'minimal' if not found.
  ThemePack getPackById(String id) {
    return _packsById[id] ?? _packsById['minimal']!;
  }

  /// Returns metadata for all registered theme packs.
  List<ThemePackMetadata> get allMetadata =>
      _packsById.values.map((p) => p.metadata).toList(growable: false);

  /// Returns all registered theme packs.
  List<ThemePack> get allPacks => _packsById.values.toList(growable: false);
}
