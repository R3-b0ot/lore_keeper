// lib/models/project.dart
import 'package:hive_flutter/hive_flutter.dart';
// Note: Hive uses references for links, not IsarLinkSet

part 'project.g.dart'; // We will generate this file!

@HiveType(typeId: 0) // Project is type 0
class Project extends HiveObject {
  @HiveField(0) // Field 0 is the title
  late String title;

  @HiveField(1) // Field 1 is the description
  String? description;

  @HiveField(2) // Field 2 is the creation date
  late DateTime createdAt;

  @HiveField(3) // Field 3 is the Book Title
  String? bookTitle;

  @HiveField(4)
  String? lastEditedChapterKey;

  @HiveField(5) // Field 4 is the Genre
  String? genre;

  @HiveField(6) // Field 5 is the Authors
  String? authors;

  @HiveField(7)
  List<String>? ignoredWords;

  @HiveField(8) // Use a new, unused index
  DateTime? lastModified;

  @HiveField(9) // Use the next available index
  int? historyLimit;

  Project({
    required this.title,
    required this.createdAt,
    this.description,
    this.bookTitle,
    this.lastEditedChapterKey,
    this.genre,
    this.authors,
    this.lastModified,
    List<String>? ignoredWords,
  }) : ignoredWords = ignoredWords ?? [];
}
