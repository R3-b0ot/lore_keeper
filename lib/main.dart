import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/magic_system.dart';
import 'package:lore_keeper/models/magic_node.dart';
import 'package:lore_keeper/models/calendar_system.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/models/section.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/models/map_data.dart';
import 'package:lore_keeper/services/trait_service.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/screens/dashboard/dashboard_screen.dart';
import 'package:lore_keeper/screens/trait_editor_screen.dart';
import 'package:lore_keeper/services/resource_manager.dart';
import 'package:lore_keeper/theme/app_theme.dart' as dracula_theme;
import 'package:lore_keeper/core/theme/app_theme.dart' as core_theme;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lore_keeper/utils/debug_logger.dart';

// Global access point for the Project data store (Hive Box)
late Box<Project> projectBox;
late Box<Section> sectionBox;
late Box<Chapter> chapterBox;
late Box<Character> characterBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global error handling ─────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    LkLog.error(
      'FLUTTER',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LkLog.error('FLUTTER', 'PlatformDispatcher error', error, stack);
    return true; // Handled — preserve default behaviour.
  };
  // ───────────────────────────────────────────────────────────────────────

  await initializeHive();
  await RelationshipService().initialize();
  await ResourceManager().initialize();
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

  void registerAdapterIfNeeded<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  registerAdapterIfNeeded(0, ProjectAdapter());
  registerAdapterIfNeeded(2, ChapterAdapter());
  registerAdapterIfNeeded(4, CharacterAdapter());
  registerAdapterIfNeeded(3, SectionAdapter());
  registerAdapterIfNeeded(5, LinkAdapter());
  registerAdapterIfNeeded(10, CharacterIterationSafeAdapter());
  registerAdapterIfNeeded(13, CharacterImageAdapter());
  registerAdapterIfNeeded(20, CustomFieldAdapter());
  registerAdapterIfNeeded(21, CustomPanelAdapter());
  registerAdapterIfNeeded(11, HistoryEntryAdapter());
  registerAdapterIfNeeded(12, CustomTraitAdapter());
  registerAdapterIfNeeded(7, MagicSystemAdapter());
  registerAdapterIfNeeded(8, MagicNodeAdapter());
  registerAdapterIfNeeded(22, MagicImageAdapter());
  registerAdapterIfNeeded(9, MagicAttributeAdapter());
  registerAdapterIfNeeded(26, CalendarSystemAdapter());
  registerAdapterIfNeeded(27, CalendarNodeAdapter());
  registerAdapterIfNeeded(28, CalendarAttributeAdapter());
  registerAdapterIfNeeded(29, TimelineEventAdapter());
  registerAdapterIfNeeded(30, MapDataAdapter());
  registerAdapterIfNeeded(31, MapLayerAdapter());
  registerAdapterIfNeeded(32, MapStampAdapter());
  registerAdapterIfNeeded(33, MapPathAdapter());
  registerAdapterIfNeeded(34, MapPolygonAdapter());
  registerAdapterIfNeeded(35, OffsetDataAdapter());

  try {
    projectBox = await Hive.openBox<Project>('projects');
    sectionBox = await Hive.openBox<Section>('sections');
    chapterBox = await Hive.openBox<Chapter>('chapters');
    characterBox = await Hive.openBox<Character>('characters');
    await Hive.openBox<MagicSystem>('magic_systems');
    await Hive.openBox<MagicNode>('magic_nodes');
    await Hive.openBox<CalendarSystem>('calendar_systems');
    await Hive.openBox<CalendarNode>('calendar_nodes');
    await Hive.openBox<Link>('links');
    await Hive.openBox<HistoryEntry>('history');
    await Hive.openBox<SimpleTrait>('custom_traits');
    await Hive.openBox<TimelineEvent>('timeline_events');
    await Hive.openBox<MapData>('map_data');
  } catch (e) {
    if (e.toString().contains('unknown typeId')) {
      await Hive.deleteBoxFromDisk('calendar_systems');
      await Hive.deleteBoxFromDisk('calendar_nodes');
      await Hive.deleteBoxFromDisk('timeline_events');
      try {
        projectBox = await Hive.openBox<Project>('projects');
        sectionBox = await Hive.openBox<Section>('sections');
        chapterBox = await Hive.openBox<Chapter>('chapters');
        characterBox = await Hive.openBox<Character>('characters');
        await Hive.openBox<MagicSystem>('magic_systems');
        await Hive.openBox<MagicNode>('magic_nodes');
        await Hive.openBox<CalendarSystem>('calendar_systems');
        await Hive.openBox<CalendarNode>('calendar_nodes');
        await Hive.openBox<Link>('links');
        await Hive.openBox<HistoryEntry>('history');
        await Hive.openBox<SimpleTrait>('custom_traits');
        await Hive.openBox<TimelineEvent>('timeline_events');
      } catch (_) {
        await Hive.deleteBoxFromDisk('projects');
        await Hive.deleteBoxFromDisk('sections');
        await Hive.deleteBoxFromDisk('chapters');
        await Hive.deleteBoxFromDisk('characters');
        await Hive.deleteBoxFromDisk('magic_systems');
        await Hive.deleteBoxFromDisk('magic_nodes');
        await Hive.deleteBoxFromDisk('links');
        await Hive.deleteBoxFromDisk('history');
        await Hive.deleteBoxFromDisk('custom_traits');
        await Hive.deleteBoxFromDisk('timeline_events');

        projectBox = await Hive.openBox<Project>('projects');
        sectionBox = await Hive.openBox<Section>('sections');
        chapterBox = await Hive.openBox<Chapter>('chapters');
        characterBox = await Hive.openBox<Character>('characters');
        await Hive.openBox<MagicSystem>('magic_systems');
        await Hive.openBox<MagicNode>('magic_nodes');
        await Hive.openBox<CalendarSystem>('calendar_systems');
        await Hive.openBox<CalendarNode>('calendar_nodes');
        await Hive.openBox<Link>('links');
        await Hive.openBox<HistoryEntry>('history');
        await Hive.openBox<SimpleTrait>('custom_traits');
        await Hive.openBox<TimelineEvent>('timeline_events');
      }
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
          theme: themeNotifier.themePack == 'dracula' ? dracula_theme.AppTheme.alucardTheme : core_theme.AppTheme.getLightTheme(themeNotifier.accessibilityRating),
          darkTheme: themeNotifier.themePack == 'dracula' ? dracula_theme.AppTheme.draculaTheme : core_theme.AppTheme.getDarkTheme(themeNotifier.accessibilityRating),
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
