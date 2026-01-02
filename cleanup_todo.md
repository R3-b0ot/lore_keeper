# Project Cleanup TODO

## Files to Remove
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
- [ ] lib/screens/project_editor_screen.dart
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
- [ ] Run flutter build to ensure no regressions
