# Lore Keeper

A desktop-first, offline-first creative writing and world-building app built with Flutter.

## Documentation

`docs/SOURCE_OF_TRUTH.md` is the only source of truth for requirements, decisions and rules. Read it before any task; it wins over any other file.

## Run

Requirements: Flutter 3.9.2 or newer, plus the platform toolchain for your target.

```bash
flutter pub get
flutter run -d windows
```

Analyze and test:

```bash
flutter analyze
flutter test
```

Never run `dart run build_runner`; it deletes the committed Hive `.g.dart` adapters.

## Docs

Start at `docs/README.md`.

## License

License: to be decided.
