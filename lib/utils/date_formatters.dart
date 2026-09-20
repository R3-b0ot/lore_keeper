/// Shared date-formatting helpers for Lore Keeper.
///
/// Centralizing these avoids replication across widgets (dashboard,
/// project book, overview, manuscript inspector) so the same human-friendly
/// date display is used everywhere.
library;

/// Formats [date] as a human-friendly relative label (e.g. "Today",
/// "Yesterday", "3d ago", "2w ago") falling back to a compact `M/d/yyyy` for
/// older dates.
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${date.month}/${date.day}/${date.year}';
}

/// Formats [date] as an absolute `d/M/yyyy HH:mm` timestamp.
String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}

/// Formats [date] as a compact `d/M/yyyy` date.
String formatDateOnly(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
