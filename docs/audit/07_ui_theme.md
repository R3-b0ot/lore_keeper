# Pass 7 — UI & Theming

> Source: direct reads of `lib/theme/*`, `lib/core/theme/*`, `theme_provider.dart`, settings controller; grep counts for hard-coded styling.

---

## 7.1 Dual theme architecture exists — new path is DEAD CODE

There are **two theme systems**:

**B. Legacy (LIVE):** `lib/theme/app_theme.dart` (`AppTheme.getDarkTheme/getLightTheme(rating)`, `app_colors.dart`, `theme_extensions.dart`) + `lib/theme/app_tokens.dart`.

**A. New "Theme Refactor" (mostly DEAD):** `lib/core/theme/*` (37 files incl. `app_theme.dart`, `theme_bootstrap.dart`, `theme_controller.dart`, `theme_registry.dart`, `theme_color_tokens.dart`, `theme_font_tokens.dart`, `accessibility_rating*.dart`, `get_app_theme_adapter.dart`, and `themes/dracula/` + `themes/minimal/` packs).

### Verified live chain
```
main.dart:35            ThemeBootstrap.initialize()            // registers minimal+dracula packs
main.dart:61            ChangeNotifierProvider(ThemeNotifier())
main.dart:98-121        themeNotifier.lightTheme / darkTheme   // consumed
theme_provider.dart:32-44  ThemeRegistry.instance.getPackById('minimal') → MinimalThemePack
minimal_theme_dark.dart:11-12  → AppTheme.getDarkTheme(rating) // ← bridges into LEGACY app_theme.dart
```
So the **live** theme builder is: `ThemeBootstrap.pack('minimal') → MinimalThemePack.buildThemeData → AppTheme.getDarkTheme/getLightTheme` — i.e. the *new* packs shell-wrap the *old* `AppTheme` color builder. **`minimal` is the only pack actually resolving to a real theme producer.**

### Dead
- `lib/core/theme/app_theme.dart` facade (`themeFromController`, lines 22-31): **zero callers in `lib/`**.
- `LegacyAppThemeAdapter` — referenced only by that facade.
- `ThemeBootstrap.createDefaultController()` — referenced only by the adapter.
- TODID step 3 in TODO.md ("update main.dart to use ThemeController") **is not done**: `main.dart` still uses `ThemeNotifier`/`ThemeRegistry`, not `ThemeController`.
- **Dracula pack** (`themes/dracula/dracula_theme_pack.dart`) is registered but nothing builds a dark/light theme from it in the live path — it is selectable in theory (pack switch in settings writes `settings['themePack']`) but its `buildThemeData` is not what main.dart uses via the minimal pack path. **Dracula is effectively unreachable in practice.** (33 `dracula` refs in tree are mostly the pack's own files.)

## 7.2 Accessibility (AA/AAA)

- `accessibility_rating.dart`/`_compat.dart` define `AccessibilityRating.aa/.aaa`; `ThemeNotifier` stores the rating and passes it to `buildThemeData` (`theme_provider.dart:48-58`).
- **Contrast is a code-level decision** — the legacy `AppTheme.getDarkTheme(rating)` branches colors per rating. There is no runtime contrast measuring anywhere in the app (the "accessibility_rating_compat", `accessibility_rating` are enums/compat shims, not measurement).
- Settings exposes AA/AAA as a global toggle (`settings_global_panes.dart:106`) with a special-case forcing the *minimal* pack (code smell).
- **Verdict:** "AA/AAA compliance" is an approximation via hard-coded palettes; **nothing enforces or verifies it** (no tests, no contrast math). Docs should not over-claim compliance.

## 7.3 Hard-coded styling density

Grep of `lib/` (excluding theme/core dirs) for direct color literals:

- `Color(0x…)` → **386 occurrences**; `Colors.<name>` → **519 occurrences**.
- Top offenders for `Color(0x`:
  - `widgets/project_book/genre_glow.dart` — **120** (pure hex gradient palette)
  - `screens/project_book_demo_screen.dart` — 39
  - `providers/calendar_tree_provider.dart` — 13 (color stored per calendar system — legitimately data-ish)
  - `models/country_data.dart` — 12 (data; fine)
  - `widgets/project_book/project_book_view.dart` — 11
  - `screens/trait_editor_screen.dart` — 10
  - `utils/calendar_icons.dart` — 9 (icon palette map; fine)
  - `widgets/species_wiki_article.dart` — 8; `widgets/calendar_main_panel.dart` — 7

The **project_book** component is the least theme-consistent (its color literals outnumber all other widgets combined) and the **calendar system** uses stored hex colors (data → UI mapping is by design, but ideally via tokens).

Percent-behind-tokens approx: most world-building widgets consume `Theme.of(context).colorScheme` correctly for chrome but inline hex for domain accents. Estimate <25% of the UI color surface is tokenized; the rest is mixed.

## 7.4 Scaling

`ScaleTokens`/`applyScale` (`settings/app_scale.dart` + `main.dart:100`) is **live only in the Settings UI** — 17 call sites (`scale.sp`, `scale.icon`, `scale.densityControl`) in `settings/widgets/settings_widgets.dart`. Not yet applied app-wide (settings describes itself as a pre-rollout option — consistent with docs "scaling settings pending").

## 7.5 Typography/icons

- Icons: **lucide_icons_flutter** (consistent usage variant across modules) — clean.
- No `GoogleFonts` dependency present in pubspec; typography is default Material `textTheme` + size overrides (the "use GoogleFonts consistently" note in AGENTS.md is not implemented).

## 7.6 Widget-layer structure

- `lib/widgets/` = 59 files / 21,020 LOC (the single largest layer, 2.7× `modules/`).
- It blends **reusable UI** (`keyboard_aware_dialog.dart`, `responsive_layout.dart`, `settings_dialog.dart`, `native_crop_dialog.dart`) with **feature-specific UI** (`manuscript_corkboard.dart`, `magic_*`, `calendar_*`, `project_book/*`, `project_editor/*`).
- Docs' `widgets/` == "Reusable UI components" is a misnomer — it's really a flat catch-all; to be refactored into `projects/editor/`-style feature trees if Clean Architecture were pursued.
- No widget/theme tokens file centralizing paddings/radii → mixed literal `EdgeInsets` throughout (grep-able; not counted per-file here).

## 7.7 Pass 7 conclusions

1. **Theme refactor is half-done and half-dead.** Live path = new pack shell + legacy AppTheme colors. `ThemeController` path unused; Dracula unreachable; `ThemeBootstrap` exists but only `minimal` matters.
2. Decision needed: finish the refactor (make `ThemeController` live, port AppTheme colors into token files, delete legacy `lib/theme`) **or** delete the core/theme facade + registry shims and keep the much simpler legacy path. Recommend finishing — the tokens scaffolding already exists.
3. AA/AAA is palette-assumed, never measured. Either add contrast tests/checks or soften the claim.
4. project_book needs a theming pass (120 hard-coded hex in one file).
5. Scaling is settings-only — document intent, don't claim app-wide support.