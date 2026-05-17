import 'package:flutter/material.dart' show ThemeData;
import 'package:meta/meta.dart';

import 'accessibility_rating.dart';

/// Immutable metadata for a theme pack.
@immutable
class ThemePackMetadata {
  final String id;
  final String displayName;
  final String description;
  final String author;
  final String version;

  const ThemePackMetadata({
    required this.id,
    required this.displayName,
    required this.description,
    required this.author,
    required this.version,
  });
}

/// A lightweight interface describing a theme pack.
///
/// Theme packs are responsible for producing [ThemeData] for light/dark
/// variants and for providing [ThemeExtension] values.
abstract class ThemePack {
  ThemePackMetadata get metadata;

  /// Build full ThemeData for the given variant.
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  });
}

/// Registry for built-in and future external themes.
class ThemeRegistry {
  final Map<String, ThemePack> _packsById = {};

  void register(ThemePack pack) {
    _packsById[pack.metadata.id] = pack;
  }

  ThemePack? getPackById(String id) => _packsById[id];

  List<ThemePackMetadata> get allMetadata =>
      _packsById.values.map((p) => p.metadata).toList(growable: false);
}
