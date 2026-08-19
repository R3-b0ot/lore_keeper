import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/utils/debug_logger.dart';

void main() {
  setUp(() {
    LkLog.clearBreadcrumbs();
  });

  group('LkLog.breadcrumb', () {
    test('records entries in chronological order', () {
      LkLog.breadcrumb('CHAR', 'first');
      LkLog.breadcrumb('CHAP', 'second');
      LkLog.breadcrumb('REF', 'third');

      final trail = LkLog.breadcrumbs;
      expect(trail.length, 3);
      expect(trail[0].area, 'CHAR');
      expect(trail[0].message, 'first');
      expect(trail[1].area, 'CHAP');
      expect(trail[1].message, 'second');
      expect(trail[2].area, 'REF');
      expect(trail[2].message, 'third');
    });

    test('retains at most 30 entries, discarding oldest', () {
      for (var i = 0; i < 35; i++) {
        LkLog.breadcrumb('A', 'msg$i');
      }

      final trail = LkLog.breadcrumbs;
      expect(trail.length, 30);
      // First five entries (0–4) should have been discarded.
      expect(trail.first.message, 'msg5');
      expect(trail.last.message, 'msg34');
    });

    test('returns an unmodifiable snapshot', () {
      LkLog.breadcrumb('A', 'x');
      final snapshot = LkLog.breadcrumbs;
      expect(() => snapshot.clear(), throwsUnsupportedError);
    });
  });

  group('LkLog API surface', () {
    test('info does not throw', () {
      expect(() => LkLog.info('TEST', 'hello'), returnsNormally);
    });

    test('debug does not throw', () {
      expect(() => LkLog.debug('TEST', 'hello'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => LkLog.warning('TEST', 'hello'), returnsNormally);
    });

    test('error does not throw', () {
      expect(
        () => LkLog.error('TEST', 'boom', Exception('e'), StackTrace.current),
        returnsNormally,
      );
    });

    test('error without stack trace does not throw', () {
      expect(
        () => LkLog.error('TEST', 'boom', Exception('e')),
        returnsNormally,
      );
    });

    test('dumpBreadcrumbs does not throw', () {
      LkLog.breadcrumb('A', 'x');
      expect(() => LkLog.dumpBreadcrumbs(), returnsNormally);
    });

    test('dumpBreadcrumbs does not throw on empty trail', () {
      expect(() => LkLog.dumpBreadcrumbs(), returnsNormally);
    });
  });
}
