import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/utils/calendar_chronology.dart';

void main() {
  group('CalendarChronology', () {
    late CalendarChronology chronology;

    setUp(() {
      chronology = CalendarChronology(
        systemKey: 1,
        daysInYear: 360,
        months: [
          ChronologyMonth(name: 'Frostmoon', days: 35, startDayOfYear: 1),
          ChronologyMonth(name: 'Thawing', days: 30, startDayOfYear: 36),
          ChronologyMonth(name: 'Blossom', days: 36, startDayOfYear: 66),
          ChronologyMonth(name: 'Rains', days: 34, startDayOfYear: 102),
          ChronologyMonth(name: 'Suncrown', days: 40, startDayOfYear: 136),
          ChronologyMonth(name: 'Highsun', days: 38, startDayOfYear: 176),
          ChronologyMonth(name: 'Harvest', days: 37, startDayOfYear: 214),
          ChronologyMonth(name: 'Leafall', days: 35, startDayOfYear: 251),
          ChronologyMonth(name: 'Mistveil', days: 35, startDayOfYear: 286),
          ChronologyMonth(name: 'Longnight', days: 40, startDayOfYear: 321),
        ],
        eras: ['First Age', 'Second Age', 'Third Age'],
        eraStartYears: [1, 1000, 2500],
        calendarName: 'Realm Calendar',
        systemName: 'Chronos',
      );
    });

    group('monthAtDayOfYear', () {
      test('day 1', () => expect(chronology.monthAtDayOfYear(1), equals(0)));
      test('day 35', () => expect(chronology.monthAtDayOfYear(35), equals(0)));
      test('day 36', () => expect(chronology.monthAtDayOfYear(36), equals(1)));
      test(
        'day 360',
        () => expect(chronology.monthAtDayOfYear(360), equals(9)),
      );
      test(
        'day 0 invalid',
        () => expect(chronology.monthAtDayOfYear(0), equals(-1)),
      );
      test(
        'day 361 invalid',
        () => expect(chronology.monthAtDayOfYear(361), equals(-1)),
      );
    });

    group('dayOfMonthAtDayOfYear', () {
      test(
        'day 1',
        () => expect(chronology.dayOfMonthAtDayOfYear(1), equals(1)),
      );
      test(
        'day 35',
        () => expect(chronology.dayOfMonthAtDayOfYear(35), equals(35)),
      );
      test(
        'day 36',
        () => expect(chronology.dayOfMonthAtDayOfYear(36), equals(1)),
      );
      test(
        'day 65',
        () => expect(chronology.dayOfMonthAtDayOfYear(65), equals(30)),
      );
      test(
        'day 360',
        () => expect(chronology.dayOfMonthAtDayOfYear(360), equals(40)),
      );
      test('invalid', () {
        expect(chronology.dayOfMonthAtDayOfYear(0), equals(-1));
        expect(chronology.dayOfMonthAtDayOfYear(361), equals(-1));
      });
    });

    group('eraAtYear', () {
      test('year 1', () => expect(chronology.eraAtYear(1), equals(0)));
      test('year 999', () => expect(chronology.eraAtYear(999), equals(0)));
      test('year 1000', () => expect(chronology.eraAtYear(1000), equals(1)));
      test('year 2499', () => expect(chronology.eraAtYear(2499), equals(1)));
      test('year 2500', () => expect(chronology.eraAtYear(2500), equals(2)));
      test('year 3000', () => expect(chronology.eraAtYear(3000), equals(2)));
      test('no eras', () {
        final noEras = CalendarChronology(
          systemKey: 2,
          daysInYear: 365,
          months: [],
          eras: [],
          eraStartYears: [],
          calendarName: 'Test',
          systemName: 'Test',
        );
        expect(noEras.eraAtYear(100), equals(-1));
      });
    });

    group('formatDisplay', () {
      test('First Age', () {
        final r = chronology.formatDisplay(500, 100);
        expect(r, contains('Blossom'));
        expect(r, contains('First Age'));
        expect(r, contains('Year 500'));
      });
      test('Second Age', () {
        final r = chronology.formatDisplay(1500, 200);
        expect(r, contains('Highsun'));
        expect(r, contains('Second Age'));
        expect(r, contains('Year 501'));
      });
      test('Third Age', () {
        final r = chronology.formatDisplay(2600, 300);
        expect(r, contains('Mistveil'));
        expect(r, contains('Third Age'));
        expect(r, contains('Year 101'));
      });
      test('invalid day', () {
        final r = chronology.formatDisplay(100, 999);
        expect(r, contains('Unknown Month'));
        expect(r, contains('?'));
      });
    });

    group('dayOfYearFromParts', () {
      test('valid', () {
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 0, dayOfMonth: 1),
          equals(1),
        );
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 0, dayOfMonth: 35),
          equals(35),
        );
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 1, dayOfMonth: 1),
          equals(36),
        );
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 9, dayOfMonth: 40),
          equals(360),
        );
      });
      test('invalid month', () {
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: -1, dayOfMonth: 1),
          equals(-1),
        );
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 10, dayOfMonth: 1),
          equals(-1),
        );
      });
      test('invalid day', () {
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 0, dayOfMonth: 0),
          equals(-1),
        );
        expect(
          chronology.dayOfYearFromParts(year: 1, monthIndex: 0, dayOfMonth: 36),
          equals(-1),
        );
      });
    });

    group('ChronologyMonth', () {
      test('endDayOfYear', () {
        expect(
          ChronologyMonth(
            name: 'Test',
            days: 30,
            startDayOfYear: 1,
          ).endDayOfYear,
          equals(30),
        );
        expect(
          ChronologyMonth(
            name: 'Test2',
            days: 35,
            startDayOfYear: 36,
          ).endDayOfYear,
          equals(70),
        );
      });
    });
  });
}
