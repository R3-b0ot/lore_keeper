# Project Cleanup TODO

## Files to Remove
- [x] Map-related files removed (map_display_provider.dart, map_creator_dialog.dart, map_list_provider.dart, map_list_pane.dart, map_module.dart, map_model.g.dart, map_service.dart, fantasy_map_display.dart, map_viewer.dart, map_display.dart)
- [ ] EXTRA/Fantasy-Map-Generator-master/ (duplicate external project)
- [ ] custom_panels_display.dart (unused file)
- [ ] lib/services/fantasy_map_generator.dart (merged into map_generator.dart)

## Code Fixes
- [ ] Remove unused imports (15 instances)
- [ ] Remove unused elements/functions (8 instances)
- [ ] Update deprecated 'value' to 'initialValue' (2 instances)
- [ ] Update deprecated 'withOpacity' to 'withValues' (6 instances)
- [ ] Remove debug print statements (12 instances)
- [ ] Fix code style issues (curly braces, final fields, etc.)

## Files to Modify
- [ ] lib/modules/character_module.dart
- [ ] lib/providers/character_list_provider.dart
- [ ] lib/screens/map_view_screen.dart
- [x] lib/screens/project_editor_screen.dart (map functionality removed)
- [ ] lib/services/map_generator.dart
- [ ] lib/services/world_generator.dart
- [ ] lib/widgets/draggable_grid.dart
- [ ] lib/widgets/fantasy_map_display.dart
- [ ] lib/widgets/map_display.dart
- [ ] lib/widgets/map_generation_loader.dart
- [ ] lib/widgets/map_generation_wizard.dart
- [ ] lib/widgets/settings_dialog.dart
- [ ] lib/widgets/world_configuration_dialog.dart
- [ ] lib/widgets/world_display.dart

## Verification
- [ ] Run flutter analyze to verify all issues resolved
- [x] Run flutter build to ensure no regressions (APK built successfully)
