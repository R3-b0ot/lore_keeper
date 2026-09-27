import 'dart:convert';

/// Canonical word/character counting for manuscript documents (MS-009/010).
///
/// Every producer of a manuscript word or character count — the live editor
/// status bar, `ManuscriptBinderService.createDocument/updateContent`, and the
/// V2→V3 migration in `DatabaseManager` — must measure through this single
/// source of truth so stored `ManuscriptDocument.wordCount/characterCount`
/// never disagrees with what the UI shows.
///
/// ## The trailing-newline decision (excluded)
///
/// A Quill Delta stores exactly one `\n` per line as its block terminator, so
/// `toPlainText()` of a single-paragraph document always ends in one `\n` that
/// the author never typed. That final `\n` is a structural artifact of the
/// Delta format, not authored content, so both measurements strip a single
/// trailing `\n` before measuring: `"Hello world\n"` counts as `11` characters
/// and `2` words. Multi-line documents keep their interior newlines (group
/// separators between lines).
final class ManuscriptTextStats {
  ManuscriptTextStats._();

  /// Strips the single structural trailing newline produced by the Delta
  /// format. Interior and additional trailing newlines are preserved.
  static String countableText(String plainText) {
    if (plainText.endsWith('\n')) {
      return plainText.substring(0, plainText.length - 1);
    }
    return plainText;
  }

  /// Canonical word count of [plainText].
  ///
  /// An empty or whitespace-only string is `0` words (a naive split of an
  /// empty string would yield 1). Words are maximal runs of non-whitespace.
  static int wordCount(String plainText) {
    final text = countableText(plainText).trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  /// Reconstructs the plain text of a stored Delta JSON document without
  /// building a Quill `Document`.
  ///
  /// Accepts either the full `{"ops":[...]}` envelope or a bare ops array (the
  /// shape some legacy V2 chapters were stored as). Text insert runs are
  /// concatenated; every embed insert (image/video/mention object) contributes
  /// the U+FFFC object-replacement character — exactly matching
  /// `Document.toPlainText()` behaviour, where the image/video embed builders
  /// and the unknown-embed fallback all yield one replacement character per
  /// embed. Non-insert ops (retain/delete) carry no authored content and are
  /// skipped. Malformed JSON yields an empty string.
  static String plainTextOfDeltaJson(String? json) {
    if (json == null || json.isEmpty) return '';
    try {
      final decoded = jsonDecode(json);
      final Iterable ops = decoded is List
          ? decoded
          : (decoded as Map)['ops'] as List? ?? const <dynamic>[];
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is! Map) continue;
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert);
        } else if (insert != null) {
          buffer.write('\uFFFC');
        }
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  /// Word count of a stored Delta JSON document (see [plainTextOfDeltaJson]).
  static int wordCountOfJson(String? json) =>
      wordCount(plainTextOfDeltaJson(json));
}
