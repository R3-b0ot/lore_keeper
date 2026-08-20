# Calendar + Timeline Overhaul — TODO

## Vision (short)
**Calendar = chronology source of truth; Timeline = events on that chronology.**

---

## Current state (bullet summary)

- **CalendarSystem** model: `name`, `projectId`, `rootNodeId`, `isConfigured` (Hive typeId 26)
- **CalendarNode** tree: hierarchical nodes with `type` (system, calendar, month, day, era, celestial, holiday, category), `attributes` (key-value), `childrenOrder` (Hive typeId 27)
- **TimelineEvent** model: `absoluteYear`, `absoluteDayOfYear` but **no calendarSystemKey** (Hive typeId 29)
- **CalendarTreeProvider**: holds all systems/nodes, exposes `systems`, `selectedSystem`, tree traversal
- **TimelineEventProvider**: CRUD for events, sorts by `absoluteYear` then `absoluteDayOfYear` globally (no per-system filter)
- **TimelineModule** (900+ lines): ad-hoc `_axis()` extracts months/eras by title parsing + attribute regex; zoom tiers (era/year/month/date); creates events with hardcoded defaults
- **CalendarModule**: wizard → CalendarMainPanel (tree editor)
- **World Building tabs**: Timeline tab exists but second column shows CalendarListPane (incorrect); Calendar tab shows CalendarListPane
- **Attributes**: wizard writes known labels (Total Days/Year, Number of Days, Era Prefix, etc.) but keys are free-text; TimelineModule scrapes via regex on label contains

---

## Phased TODO

### Phase CT-0 — Documentation
- [x] This TODO file

---

### Phase CT-1 — CalendarChronology service (FOUNDATION — implement next)
- [x] Pure Dart service (`lib/utils/calendar_chronology.dart`)
- [x] Input: CalendarTreeProvider data or a snapshot of nodes for a `systemKey`
- [x] API at minimum:
  - `daysInYear(systemKey)` → `int`
  - `months(systemKey)` → ordered `{name, days, startDayOfYear}`
  - `eras(systemKey)` → ordered names/ids
  - `dayOfYear({year, monthIndex, dayOfMonth})` / inverse where possible
  - `formatDisplay(systemKey, absoluteYear, absoluteDayOfYear)` → human string
  - `monthAtDayOfYear(systemKey, dayOfYear)` → month index
  - `eraAtYear(systemKey, year)` → era index/name
- [x] Unit tests with a seeded fantasy calendar (uneven months, multiple eras)
- [x] Timeline must call this instead of scraping the tree inline
- [x] **Run `flutter test test/utils/calendar_chronology_test.dart` → 27/27 PASS**
- [x] **Wizard-key normalization**: `_readPositiveInt` uses normalized keys (underscore-lowercase) for `total_days_year`, `number_of_days`, `start_year`, etc. with substring fallback

---

### Phase CT-2 — TimelineEvent schema + provider
- [x] Add `calendarSystemKey` (or system id) to TimelineEvent (Hive field, migration-safe — new field at end)
- [x] Optional: `durationDays` (default 0)
- [x] Optional stubs for `linkedCharacterIds` / `linkedLocationIds` (empty lists OK)
- [x] Provider: create/update filter by system; require system on create
- [x] Sort remains year then dayOfYear **within system**
- [x] Run `dart run build_runner build --delete-conflicting-outputs` (adapter generated ✓)

---

### Phase CT-3 — Wire World Building sidebars
- [x] Timelines tab → second column = event list (not CalendarListPane)
- [x] Calendars tab → CalendarListPane
- [x] Empty states: no configured calendar → CTA to Calendars tab
- [x] Wire `CalendarTreeProvider.selectedSystemKey` into `TimelineEventProvider`

---

### Phase CT-4 — Timeline canvas refactor (use Chronology) — **COMPLETED**
- [x] **Replaced ad-hoc `_axis()` tree scraping** with `CalendarChronology.fromProvider()` calls
- [x] **Axis labels from CalendarChronology** — months, eras, totalDays all sourced from chronology
- [x] **Create event defaults to selected system + sensible date** — `_createEvent()` uses `chronology.daysInYear / 2` and passes `calendarSystemKey: chronology.systemKey`
- [x] **Zoom tiers keep working with correct month/era labels** — `_trackWidth`, `_x`, `_dateFor`, `_label` all use chronology
- [x] **Removed dead code**: `_AxisData`, `_Month` classes removed; `_RelDate` retained for UI rendering
- [x] `flutter analyze` clean on all touched files
- [x] `flutter test test/utils/calendar_chronology_test.dart` passes (27/27)

---

### Phase CT-5 — Inspector + links
- [ ] Rich date editing via chronology
- [ ] `durationDays` UI
- [ ] Link characters/locations (reuse existing selection patterns if any)

---

### Phase CT-6 — Calendar polish
- [ ] Month grid view from chronology
- [ ] Validation: sum of month days vs totalDays
- [ ] Theme token cleanup in calendar modules

---

### Phase CT-7 — Lanes / filters / ranges (later)
- [ ] Swimlanes, filters, Gantt-style ranges, minimap

---

### Phase CT-8 — Chronicles (later)
- [ ] Map focus / Overview embeds

---

## Success criteria (copied from plan)
- [ ] A project has at least one **configured** calendar system (wizard completed)
- [ ] Every TimelineEvent has a `calendarSystemKey` pointing to a valid system
- [ ] Timeline canvas shows correct era/month labels from that calendar at every zoom tier
- [ ] Creating an event in Timelines tab defaults to the selected calendar system
- [ ] Timelines tab second column = event list; Calendars tab second column = calendar tree
- [ ] `flutter analyze` clean on touched files
- [ ] `flutter test` passes (new chronology tests + existing)

---

## Out of scope for early phases
- Full Map Chronicles
- Plottr-complete arcs UI
- Community themes
- Multiplayer / live collab

---

## Hive Migration Notes (for CT-2)
- **TimelineEvent** typeId: 29 — add `calendarSystemKey` as new highest field number (e.g., 11), default to 0 or -1 to indicate "unassigned"
- Run `dart run build_runner build --delete-conflicting-outputs` after model change
- On first load, existing events without system: assign to first configured system or mark as unassigned (filter out until migrated)
- CalendarSystem typeId: 26 — no change needed
- CalendarNode typeId: 27 — no change needed

---

## Next session starts at
- CT-5: Inspector + links (rich date editing via chronology, durationDays UI, link characters/locations)