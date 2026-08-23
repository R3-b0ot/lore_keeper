import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/section.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:lore_keeper/core/theme/theme_bootstrap.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/screens/dashboard/dashboard_screen.dart';
import 'package:lore_keeper/services/resource_manager.dart';
import 'package:lore_keeper/database/database_manager.dart';

import 'package:flutter/foundation.dart';
import 'package:lore_keeper/utils/debug_logger.dart';

/// Global access points for frequently-used Hive boxes.
///
/// These are assigned once during [initializeDatabase] and read by services
/// and providers throughout the application. They are kept for backward
/// compatibility; prefer using [DatabaseManager.instance] for new code.
late Box<Project> projectBox;
late Box<Section> sectionBox;
late Box<Chapter> chapterBox;
late Box<Character> characterBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeBootstrap.initialize();

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

  await initializeDatabase();
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

/// Central database initialization via [DatabaseManager].
///
/// Uses [getApplicationSupportDirectory] to match the original Hive storage
/// path exactly — critical for locating existing legacy data.
/// On web, falls back to default Hive.initFlutter() path.
Future<void> initializeDatabase() async {
  if (kIsWeb) {
    await DatabaseManager.instance.initialize();
  } else {
    final dir = await getApplicationSupportDirectory();
    await DatabaseManager.instance.initialize(path: dir.path);
  }

  // Assign global box references for backward compatibility.
  final db = DatabaseManager.instance;
  projectBox = db.projects;
  sectionBox = db.sections;
  chapterBox = db.chapters;
  characterBox = db.characters;
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
          theme: themeNotifier.lightTheme,
          darkTheme: themeNotifier.darkTheme,
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
