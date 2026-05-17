# TODO — Lore Keeper Theme Refactor (Modular Theme Architecture)

## Step 1 — Scaffold new theme architecture
- [ ] Create `lib/core/theme/app_theme.dart` (new composition layer)
- [ ] Create `lib/core/theme/theme_controller.dart` (runtime switching + caching + persistence hooks)
- [ ] Create `lib/core/theme/theme_registry.dart` (ThemePack registry + metadata)
- [ ] Create design token files under `lib/core/theme/tokens/`
  - [ ] colors.dart
  - [ ] spacing.dart
  - [ ] typography.dart
  - [ ] radius.dart
  - [ ] shadows.dart
  - [ ] motion.dart
- [ ] Create ThemeExtension files under `lib/core/theme/theme_extensions/`
  - [ ] lore_card_theme_extension.dart
  - [ ] journal_theme_extension.dart
  - [ ] codex_panel_theme_extension.dart
  - [ ] timeline_theme_extension.dart
  - [ ] rarity_theme_extension.dart
  - [ ] worldbuilding_theme_extension.dart

## Step 2 — Add “minimal” pack that reproduces current visuals
- [ ] Create `lib/core/theme/themes/minimal/minimal_theme_pack.dart`
- [ ] Create `lib/core/theme/themes/minimal/minimal_theme_light.dart`
- [ ] Create `lib/core/theme/themes/minimal/minimal_theme_dark.dart`
- [ ] Ensure output matches current `lib/theme/app_theme.dart` + `lib/theme/app_colors.dart` (AA/AAA)

## Step 3 — Wire controller into app + persistence
- [ ] Update `lib/main.dart` to use ThemeController-produced ThemeData
- [ ] Update `lib/providers/theme_provider.dart` or replace it with controller persistence
- [ ] Ensure existing AA/AAA and system/light/dark behavior stays identical

## Step 4 — Create themed components (start with card/button/textfield stack)
- [ ] Implement `lib/core/theme/themed_widgets/lore_button.dart`
- [ ] Implement `lib/core/theme/themed_widgets/lore_card.dart`
- [ ] Implement `lib/core/theme/themed_widgets/lore_textfield.dart`
- [ ] Add themed background component if needed for key screens

## Step 5 — Migration rollout (no visual regressions)
- [ ] Identify first set of widgets using direct styling (cards/buttons/textfields)
- [ ] Replace with themed components and ThemeExtensions
- [ ] Keep legacy style code until each component is migrated

## Step 6 — Compatibility hooks for future JSON themes
- [ ] Define JSON schema mapping into ThemePack
- [ ] Add registry API for external pack registration

## Verification
- [ ] Run `flutter analyze`
- [ ] Run `flutter test` (if present)
- [ ] Manual check: theme switching + AA/AAA contrast works

