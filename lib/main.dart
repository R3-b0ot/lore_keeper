import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/models/section.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/services/trait_service.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/screens/dashboard/dashboard_screen.dart';
import 'package:lore_keeper/screens/trait_editor_screen.dart';
import 'package:lore_keeper/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Global access point for the Project data store (Hive Box)
late Box<Project> projectBox;
late Box<Section> sectionBox;
late Box<Chapter> chapterBox;
late Box<Character> characterBox;
late Box<MapModel> mapBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeHive();
  await RelationshipService().initialize();
  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const LoreKeeperApp(),
      ),
    ),
  );
}

Future<void> initializeHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Directory dir = await getApplicationSupportDirectory();
    await Hive.initFlutter(dir.path);
  }

  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ChapterAdapter());
  Hive.registerAdapter(CharacterAdapter());
  Hive.registerAdapter(SectionAdapter());
  Hive.registerAdapter(LinkAdapter());
  Hive.registerAdapter(CharacterIterationSafeAdapter());
  Hive.registerAdapter(CharacterImageAdapter());
  Hive.registerAdapter(CustomFieldAdapter());
  Hive.registerAdapter(CustomPanelAdapter());
  Hive.registerAdapter(CustomTraitAdapter());
  Hive.registerAdapter(MapModelAdapter());
  Hive.registerAdapter(HistoryEntryAdapter());

  try {
    projectBox = await Hive.openBox<Project>('projects');
    sectionBox = await Hive.openBox<Section>('sections');
    chapterBox = await Hive.openBox<Chapter>('chapters');
    characterBox = await Hive.openBox<Character>('characters');
    mapBox = await Hive.openBox<MapModel>('maps');
    await Hive.openBox<Link>('links');
    await Hive.openBox<HistoryEntry>('history');
    await Hive.openBox<SimpleTrait>('custom_traits');
  } catch (e) {
    if (e.toString().contains('unknown typeId')) {
      await Hive.deleteBoxFromDisk('projects');
      await Hive.deleteBoxFromDisk('sections');
      await Hive.deleteBoxFromDisk('chapters');
      await Hive.deleteBoxFromDisk('characters');
      await Hive.deleteBoxFromDisk('maps');
      await Hive.deleteBoxFromDisk('links');
      await Hive.deleteBoxFromDisk('history');
      await Hive.deleteBoxFromDisk('custom_traits');

      projectBox = await Hive.openBox<Project>('projects');
      sectionBox = await Hive.openBox<Section>('sections');
      chapterBox = await Hive.openBox<Chapter>('chapters');
      characterBox = await Hive.openBox<Character>('characters');
      mapBox = await Hive.openBox<MapModel>('maps');
      await Hive.openBox<Link>('links');
      await Hive.openBox<HistoryEntry>('history');
      await Hive.openBox<SimpleTrait>('custom_traits');
    } else {
      rethrow;
    }
  }
}

class LoreKeeperApp extends StatelessWidget {
  const LoreKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Lore Keeper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(themeNotifier.accessibilityRating),
          darkTheme: AppTheme.getDarkTheme(themeNotifier.accessibilityRating),
          themeMode: themeNotifier.themeMode,
          home: const DashboardScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
        );
      },
    );
  }
}
