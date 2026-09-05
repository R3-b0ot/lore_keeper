import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Lightweight debug-only logger for Lore Keeper.
///
/// Uses [dart:developer] so output appears in the VS Code Debug Console.
/// All logging is dead-stripped in release builds via [kDebugMode].
/// Never throw — every public member wraps its body in a try/catch.
final class LkLog {
  LkLog._();

  // ── Public API ──────────────────────────────────────────────────────────

  static void info(String area, String message, {Object? data}) {
    _log(area, message, data: data, level: 0);
  }

  static void debug(String area, String message, {Object? data}) {
    _log(area, message, data: data, level: -1);
  }

  static void warning(String area, String message, {Object? data}) {
    _log(area, message, data: data, level: 1);
  }

  static void error(
    String area,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(area, message, error: error, stackTrace: stackTrace, level: 3);
  }

  // ── Breadcrumbs ─────────────────────────────────────────────────────────

  static const int _maxBreadcrumbs = 30;
  static final List<_Breadcrumb> _breadcrumbs = [];

  static void breadcrumb(String area, String message) {
    try {
      _breadcrumbs.add(_Breadcrumb(area: area, message: message));
      if (_breadcrumbs.length > _maxBreadcrumbs) {
        _breadcrumbs.removeAt(0);
      }
    } catch (_) {}
  }

  static List<({String area, String message})> get breadcrumbs {
    try {
      return List.unmodifiable(
        _breadcrumbs.map((b) => (area: b.area, message: b.message)),
      );
    } catch (_) {
      return const [];
    }
  }

  static void dumpBreadcrumbs() {
    try {
      if (_breadcrumbs.isEmpty) {
        developer.log('[LK] No breadcrumbs recorded.', name: 'LK.breadcrumb');
        return;
      }
      final buf = StringBuffer()
        ..writeln('[LK] Breadcrumb trail (${_breadcrumbs.length}):');
      for (var i = 0; i < _breadcrumbs.length; i++) {
        final b = _breadcrumbs[i];
        buf.writeln('  $i │ [${b.area}] ${b.message}');
      }
      developer.log(buf.toString(), name: 'LK.breadcrumb');
    } catch (_) {}
  }

  /// Exposed for tests only — clears the breadcrumb ring.
  @visibleForTesting
  static void clearBreadcrumbs() {
    _breadcrumbs.clear();
  }

  // ── Internals ───────────────────────────────────────────────────────────

  static void _log(
    String area,
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
    required int level,
  }) {
    if (!kDebugMode) return;
    try {
      final tag = '[LK][$area]';
      final buf = StringBuffer('$tag $message');
      if (data != null) buf.write(' | $data');

      developer.log(
        buf.toString(),
        name: 'LK.$area',
        level: level < 0 ? 0 : level,
        error: error,
        stackTrace: stackTrace,
      );

      breadcrumb(area, message);
    } catch (_) {}
  }
}

// ── Internal breadcrumb model ──────────────────────────────────────────────

class _Breadcrumb {
  _Breadcrumb({required this.area, required this.message});
  final String area;
  final String message;
}
