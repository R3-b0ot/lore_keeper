import 'package:lore_keeper/core/theme/theme_controller.dart';
import 'package:lore_keeper/core/theme/theme_registry.dart';
import 'package:lore_keeper/core/theme/themes/dracula/dracula_theme_pack.dart';
import 'package:lore_keeper/core/theme/themes/minimal/minimal_theme_pack.dart';

/// Bootstrap utility to initialize built-in theme packs at application startup.
class ThemeBootstrap {
  static bool _initialized = false;

  /// Registers built-in dual theme packs (`minimal` and `dracula`) in [ThemeRegistry.instance].
  static void initialize() {
    if (_initialized) return;
    ThemeRegistry.instance.register(const MinimalThemePack());
    ThemeRegistry.instance.register(const DraculaThemePack());
    _initialized = true;
  }

  static ThemeRegistryAdapter buildRegistryAdapter() {
    initialize();
    return _DefaultThemeRegistryAdapter();
  }

  static ThemeRegistryAdapter defaultRegistryAdapter() =>
      buildRegistryAdapter();

  static ThemeController createDefaultController() {
    initialize();
    return ThemeController(registry: defaultRegistryAdapter());
  }
}

class _DefaultThemeRegistryAdapter implements ThemeRegistryAdapter {
  _DefaultThemeRegistryAdapter();

  @override
  dynamic getPackById(String id) {
    return ThemeRegistry.instance.getPackById(id);
  }
}
