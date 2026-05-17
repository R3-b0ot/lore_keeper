import 'package:lore_keeper/core/theme/theme_controller.dart';
import 'package:lore_keeper/core/theme/theme_registry.dart';
import 'package:lore_keeper/core/theme/themes/minimal/minimal_theme_pack.dart';

/// Builds a default theme registry and controller for app startup.
class ThemeBootstrap {
  static ThemeRegistryAdapter buildRegistryAdapter() {
    return _DefaultThemeRegistryAdapter();
  }

  static ThemeRegistryAdapter defaultRegistryAdapter() =>
      buildRegistryAdapter();

  static ThemeController createDefaultController() {
    return ThemeController(registry: defaultRegistryAdapter());
  }
}

class _DefaultThemeRegistryAdapter implements ThemeRegistryAdapter {
  final ThemeRegistry _registry = ThemeRegistry();

  _DefaultThemeRegistryAdapter() {
    _registry.register(const MinimalThemePack());
  }

  @override
  dynamic getPackById(String id) {
    return _registry.getPackById(id);
  }
}
