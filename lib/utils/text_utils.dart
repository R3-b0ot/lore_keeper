import 'dart:convert';

/// A utility class for text processing operations
class TextUtils {
  /// Advanced word counting method that handles various edge cases
  ///
  /// Counts words in text using sophisticated algorithm that handles:
  /// - Unicode word boundaries for Latin text
  /// - Character-based counting for CJK languages
  /// - Multiple consecutive spaces
  /// - Punctuation and special characters
  /// - HTML tags and formatting
  /// - International text
  static int countWords(String text) {
    if (text.isEmpty) return 0;

    // Remove HTML tags first
    String plainText = text.contains('<')
        ? text.replaceAll(RegExp(r'<[^>]*>'), '')
        : text;

    // 1. Count CJK characters (Chinese, Japanese, Korean)
    // Common CJK ranges
    final cjkRegex = RegExp(
      r'[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]',
    );
    int cjkCount = cjkRegex.allMatches(plainText).length;

    // 2. Count Latin-based words
    // Replace CJK characters with space to avoid interfering with Latin word matching
    String latinOnly = plainText.replaceAll(cjkRegex, ' ');

    // Match words: sequences of alphanumeric chars, allowing for internal hyphens or apostrophes
    // e.g. "word", "don't", "co-op", "user's"
    final latinWordRegex = RegExp(r"[a-zA-Z0-9_]+(?:['’-][a-zA-Z0-9_]+)*");
    int latinCount = latinWordRegex.allMatches(latinOnly).length;

    return cjkCount + latinCount;
  }

  /// Extracts plain text from rich text JSON for word counting
  ///
  /// Parses rich text JSON and extracts text content for accurate word counting.
  static String extractPlainTextFromRichTextJson(String? richTextJson) {
    if (richTextJson == null || richTextJson.isEmpty) return '';

    try {
      // Try to parse as JSON first
      final dynamic jsonData = jsonDecode(richTextJson);

      // Handle different formats
      List<dynamic> ops;
      if (jsonData is List) {
        ops = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('ops')) {
        ops = jsonData['ops'] as List<dynamic>;
      } else {
        // Fallback to simple regex if JSON structure is unexpected
        return richTextJson
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      // Extract text from operations
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          } else if (insert is Map) {
            // Handle embed objects (like images), ignore them for word count
            continue;
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      // If JSON parsing fails, fallback to simple regex
      return richTextJson
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }
}
