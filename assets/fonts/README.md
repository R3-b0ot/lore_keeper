# Open-Source Fonts

This directory contains open-source fonts for use in the Lore Keeper application.

## Font Policy

Only fonts with permissive open-source licenses may be included:
- SIL Open Font License (OFL) 
- Apache License 2.0
- MIT License
- BSD License

## Currently Used Fonts

The application currently uses system fonts and Material Design default fonts.

## Adding New Fonts

When adding fonts:

1. Verify the license allows redistribution
2. Add font files (.ttf or .otf) to this directory  
3. Update pubspec.yaml under the `fonts:` section
4. Run `flutter pub get`
5. Update theme configuration in `lib/theme/app_theme.dart`

## Font Resources

- [Google Fonts](https://fonts.google.com/) - Many open-source fonts
- [Font Squirrel](https://www.fontsquirrel.com/) - Free fonts for commercial use
- [Open Font Library](https://fontlibrary.org/) - Open-source font community