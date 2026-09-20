# TODO — Lore Keeper Theme Work (Modular Theme Architecture)

> Status note: the `ThemeController` / `themeFromController` path (former "Step 3") was removed as dead code —
> no callers existed. The live chain is `ThemeBootstrap.initialize()` → `ThemeRegistry` → theme packs →
> legacy `AppTheme`. Do not reintroduce the controller path.

## Step 2 — “minimal” pack that reproduces current visuals (DONE)

- [x] Create `lib/core/theme/themes/minimal/minimal_theme_pack.dart`
- [x] Create `lib/core/theme/themes/minimal/minimal_theme_light.dart`
- [x] Create `lib/core/theme/themes/minimal/minimal_theme_dark.dart`
- [x] Ensure output matches current `lib/theme/app_theme.dart` + `lib/theme/app_colors.dart` (AA/AAA)

## Step 1 — Design token files under `lib/core/theme/tokens/`

- [ ] colors.dart
- [ ] spacing.dart
- [ ] typography.dart
- [ ] radius.dart
- [ ] shadows.dart
- [ ] motion.dart

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
- [ ] Run `flutter test`
- [ ] Manual check: theme switching + AA/AAA contrast works