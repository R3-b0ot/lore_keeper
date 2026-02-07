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
  dynamic lastEditedChapterKey;

  @HiveField(5) // Field 4 is the Genre
  String? genre;

  @HiveField(6) // Field 5 is the Authors
  String? authors;

  @HiveField(7)
  List<String>? ignoredWords;

  @HiveField(8) // Use a new, unused index
  DateTime? lastModified;

  @HiveField(9)
  int? historyLimit;

  @HiveField(10)
  String? coverImagePath;

  @HiveField(11)
  bool? showTitleOnCover;

  @HiveField(12)
  bool? showAuthorOnCover;

  @HiveField(13)
  String? authorBio;

  @HiveField(14)
  String? authorEmail;

  @HiveField(15)
  String? authorWebsite;

  @HiveField(16)
  String? authorTwitter;

  @HiveField(17)
  String? authorInstagram;

  @HiveField(18)
  String? authorFacebook;

  Project({
    required this.title,
    required this.createdAt,
    this.description,
    this.bookTitle,
    this.lastEditedChapterKey,
    this.genre,
    this.authors,
    this.lastModified,
    this.historyLimit,
    this.coverImagePath,
    this.showTitleOnCover = true,
    this.showAuthorOnCover = true,
    this.authorBio,
    this.authorEmail,
    this.authorWebsite,
    this.authorTwitter,
    this.authorInstagram,
    this.authorFacebook,
    List<String>? ignoredWords,
  }) : ignoredWords = ignoredWords ?? [];
}
