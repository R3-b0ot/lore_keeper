# Theme Engine

## Goals

1. **Dual ThemePacks** — every pack defines **dark** and **light**.
2. **Dracula pack** follows the **official Dracula Theme Spec** (Dracula Classic + Alucard Classic).
3. **Fonts and colors exposed** so community themes can be added later (VS Code–like model).
4. **UI never hard-codes brand colors** — only tokens / ThemeData / ThemeExtensions.
5. **AccessibilityRating** (AA / AAA) remains a cross-cutting concern on top of pack tokens.

## ThemePack contract

```text
ThemePack
  metadata: id, displayName, description, author, version
  darkColors: ThemeColorTokens
  lightColors: ThemeColorTokens
  fonts: ThemeFontTokens          # exposed for community packs
  buildThemeData(isDark, accessibilityRating) → ThemeData
```

- Selecting a pack chooses the *pair*.  
- `ThemeMode` (system | light | dark) chooses which half is active.  
- Custom packs (future) ship the same dual structure + optional font assets.

## ThemeColorTokens (minimum)

Surfaces, text, accents, functional UI — enough for app chrome *and* alignment with Dracula UI/syntax tokens where useful.

**Surfaces:** background, backgroundDarker, backgroundDark, backgroundLight, backgroundLighter, floating, selection, currentLine  

**Text:** foreground, comment (muted)  

**Accents:** pink, purple, cyan, green, orange, yellow, red  

**Functional:** functionalRed, functionalOrange, functionalGreen, functionalCyan, functionalPurple  

Packs may add optional syntax/ANSI maps later for manuscript code blocks or embedded tools.

## ThemeFontTokens (exposed)

```text
displayFamily   # headings, brand, section labels
bodyFamily      # long-form reading/writing
monoFamily      # metadata, shortcuts, counts
```

Future community packs may include:

- Family names only (system / Google Fonts), or  
- Bundled font file paths declared in pack manifest.

Do **not** bake Cinzel/Crimson into the engine as the only option — Figma prototype fonts can be a *named pack*, not the core.

## Built-in packs (phase 0)

| Pack ID | Dark | Light | Notes |
|---------|------|-------|-------|
| `dracula` | Dracula Classic | Alucard Classic | Exact hex from official Dracula Theme Spec |
| `minimal` | Current product default dark | Current product default light | Bridge until literary/other packs |

Register both in `ThemeRegistry`. Remove special-casing `themePack == 'dracula'` in `main.dart`.

### Dracula Classic (dark) — key values

| Token | Hex |
|-------|-----|
| Background | `#282A36` |
| Background Darker | `#191A21` |
| Background Dark | `#21222C` |
| Background Light / Floating | `#343746` |
| Background Lighter | `#424450` |
| Current Line / Comment | `#6272A4` |
| Selection | `#44475A` |
| Foreground | `#F8F8F2` |
| Pink | `#FF79C6` |
| Purple | `#BD93F9` |
| Cyan | `#8BE9FD` |
| Green | `#50FA7B` |
| Orange | `#FFB86C` |
| Yellow | `#F1FA8C` |
| Red | `#FF5555` |
| Line highlight fallback | `#353747` |

### Alucard Classic (light) — key values

| Token | Hex |
|-------|-----|
| Background | `#FFFBEB` |
| Background Darker | `#BCBAB3` |
| Background Dark | `#CECCC0` |
| Background Light | `#DEDCCF` |
| Background Lighter | `#ECE9DF` |
| Floating | `#EFEDDC` |
| Current Line / Comment | `#6C664B` |
| Selection | `#CFCFDE` |
| Foreground | `#1F1F1F` |
| Pink | `#A3144D` |
| Purple | `#644AC9` |
| Cyan | `#036A96` |
| Green | `#14710A` |
| Orange | `#A34D14` |
| Yellow | `#846E15` |
| Red | `#CB3A2A` |
| Line highlight fallback | `#E2DECA` |

### Functional colors (spec, shared intent)

| Token | Hex |
|-------|-----|
| Functional Red | `#DE5735` |
| Functional Orange | `#A39514` |
| Functional Green | `#089108` |
| Functional Cyan | `#0081D6` |
| Functional Purple | `#815CD6` |

Use functional colors for success/warning/error/info/focus in **app UI**. Syntax accents (pink as primary in Dracula) map to primary/secondary in ColorScheme as appropriate.

## Mapping to Flutter ColorScheme

Guideline (not rigid for every pack):

- `surface` / `scaffoldBackgroundColor` ← background  
- `onSurface` ← foreground  
- `primary` ← pink (Dracula) or pack primary  
- `secondary` ← purple  
- `tertiary` ← cyan  
- `error` ← red or functionalRed  
- `outline` ← subtle border from currentLine / muted with alpha  

ThemeExtensions may carry full `ThemeColorTokens` for widgets that need selection, currentLine, floating, etc.

## Community themes (future)

VS Code–like direction:

1. **Pack format** (JSON or folder): metadata, dark tokens, light tokens, font families, optional font files.  
2. **Loader** registers into `ThemeRegistry` at runtime.  
3. **Discovery** later (repo, zip import, in-app gallery).  

Phase 0 only needs: stable interfaces + built-in packs + persistence of selected pack id via existing ThemeNotifier settings box.

## Compatibility

- Existing `ThemeNotifier` keys (`themePack`, `themeMode`, `accessibilityRating`) should keep working.  
- Migrate stored `'dracula'` to the dual pack (dark=Classic, light=Alucard).  
- Deprecate parallel `lib/theme/app_theme.dart` special cases once packs build full ThemeData.
