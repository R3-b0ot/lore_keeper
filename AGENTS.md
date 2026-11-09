# Lore Keeper agent instructions

Read `docs/SOURCE_OF_TRUTH.md` first. It is the only source of truth for requirements, decisions and rules, and it wins over any other file.

## Engineering rules (from Constraints)

- Never run `dart run build_runner`. It deletes the committed `.g.dart` Hive adapters. Edit adapters by hand.
- `flutter analyze` must report zero issues and `flutter test` must pass before any task is called done.
- Layering: models, then database, then services, then providers, then modules and widgets, then screens. Widgets never open Hive boxes.
- State uses Provider with ChangeNotifier. Do not add Riverpod providers; the Riverpod scope in main.dart is reserved.
- Use the debug logger, not print.
- Check a third-party package's current documentation before using its API.
