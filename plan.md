# Map Module Removal Plan

## 1. Source Code & Logic (The Amputation List)

### Directories and Files Dedicated to Maps (Complete Removal Candidates)
```
lib/data/maps/ (entire directory)
├── models/map_project_model.dart
├── models/map_project_model.g.dart
├── repositories/hive_map_repository.dart
├── serializers/map_city_codec.dart
├── serializers/map_feature_codec.dart
├── services/fmg_import_service.dart

lib/domain/maps/ (entire directory)
├── commands/ (all map_command.dart, add_terrain_stroke_command.dart, etc.)
├── entities/ (map_city.dart, map_project.dart, map_river.dart, etc.)
├── repositories/map_repository.dart
└── services/ (map_generator.dart, map_river_generator.dart, etc.)
├── usecases/ (create_map_project.dart, etc.)

lib/presentation/maps/ (entire directory)
├── map_module.dart
├── providers/map_editor_provider.dart
├── providers/map_list_provider.dart
├── rendering/map_rasterizer.dart
├── tools/ (map_tool.dart, ink_map_tools.dart, etc.)
└── widgets/ (map_canvas.dart, map_editor_panel.dart, map_list_pane.dart, map_creator_dialog.dart)

lib/models/map_model.g.dart
lib/providers/map_display_provider.dart  (likely)
lib/providers/map_list_provider.dart     (likely)
lib/screens/map_view_screen.dart         (likely)
lib/services/map_service.dart            (likely)
lib/widgets/fantasy_map_display.dart     (likely)
lib/widgets/map_creator_dialog.dart      (likely)
lib/widgets/map_list_pane.dart           (likely)
```

### Ghost References (Cross-file Dependencies)
- **lib/main.dart**: Imports `data/maps/models/map_project_model.dart`; uses `mapProjectBox`; registers `MapProjectModelAdapter()`.
- **lib/widgets/project_editor/module_sidebar.dart**: Likely references Map module in `moduleItems` list (imports ProjectEditorModuleItem which probably includes map).
- **lib/screens/project_editor_screen.dart**: (needs verification) Likely integrates MapModule.
- **lib/modules/**: No `lib/modules/map_module.dart` found; map module is under `presentation/maps/map_module.dart`.
- **lib/screens/dashboard/dashboard_screen.dart**: No direct map references.
- Other potential: Search for imports like `import 'package:lore_keeper/presentation/maps/map_module.dart'` or `MapModule()` usages in project_editor files.

## 2. Dependency & Asset Cleanup
- **pubspec.yaml**: No map-specific packages (no google_maps_flutter, flutter_map, geolocator, latlong2 found). Safe: none to remove.
- **Assets**: No map-specific assets identified in `assets/` (no markers, map styles, geojson). Safe: none to remove.

## 3. Platform-Specific \"Scrubbing\"
- **Android** (`android/app/src/main/AndroidManifest.xml`): No location permissions, map API keys, or map activities. Safe: none.
- **iOS** (`ios/Runner/Info.plist`): No `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`, or map-related keys. Safe: none.

## 4. Step-by-Step Deletion Order
1. **Remove map Hive integration**:
   - Edit `lib/main.dart`: Remove map_model import, adapter registration, `mapProjectBox`, related Hive.openBox and deleteBoxFromDisk calls.
   - Test: `flutter run` (ensure no Hive errors).

2. **Remove dedicated map directories**:
   - Delete `lib/data/maps/`, `lib/domain/maps/`, `lib/presentation/maps/`.
   - Verify no imports from these in remaining code.
   - Test: `flutter analyze` (fix any unresolved imports).

3. **Remove map screens/widgets/providers**:
   - Delete `lib/models/map_model.g.dart`, map providers, screens, widgets listed above.
   - Test: `flutter analyze`.

4. **Remove ghost references**:
   - Edit `lib/widgets/project_editor/module_sidebar.dart` (remove Map module item from list).
   - Edit `lib/screens/project_editor_screen.dart`, any module resolver to exclude map.
   - Regenerate any .g.dart files if needed (`flutter packages pub run build_runner build`).

5. **Final cleanup**:
   - `flutter clean`
   - `flutter pub get`
   - `flutter analyze`
   - Test app launch and project editor navigation (confirm no map module appears).

**Total Impact**: Removes ~80 files. Minimal disruption expected due to modular design. No external deps or platform changes needed. After deletion, project editor will have fewer modules (calendar, character, magic, manuscript, timeline).

