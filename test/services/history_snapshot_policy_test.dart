/// HistorySnapshotPolicy (Cycle 3b, item 2) — MS-008 / S-34 follow-up.
///
/// The policy is the single place that answers "should a ManuscriptDocument
/// history snapshot be written right now?". Content autosave and history
/// snapshots are deliberately decoupled: content reaches storage every ~2s
/// (S-34), while snapshots are paced and change-gated, so the history panel
/// stays a record of *edits* instead of a record of keystroke batches.
///
/// These are unit tests on the policy itself — no widget, no Hive. The editor
/// integration is guarded separately in
/// `test/widgets/manuscript_history_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/services/history_snapshot_policy.dart';

const _stored = '{"ops":[{"insert":"Hello world\\n"}]}';
const _edited = '{"ops":[{"insert":"Goodbye world\\n"}]}';

void main() {
  group('HistorySnapshotPolicy — identical content is never snapshotted', () {
    test('an autosave of unchanged content writes nothing', () {
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _stored,
        lastSnapshottedRichTextJson: _stored,
        sinceLastSnapshot: const Duration(hours: 1),
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(decision.shouldSnapshot, isFalse);
      expect(decision.skipReason, HistorySnapshotSkip.identicalContent);
    });

    test('a close/switch of unchanged content writes nothing either', () {
      // The close trigger is unconditional for *changed* content, but it must
      // not resurrect the identical-content case: closing a document nobody
      // edited is not a revision.
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _stored,
        lastSnapshottedRichTextJson: _stored,
        sinceLastSnapshot: const Duration(hours: 1),
        trigger: HistorySnapshotTrigger.documentClose,
      );

      expect(decision.shouldSnapshot, isFalse);
      expect(decision.skipReason, HistorySnapshotSkip.identicalContent);
    });

    test('a null baseline (never snapshotted) still refuses null content', () {
      // A brand-new, untouched document is 'null -> null'. That is not a change.
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: null,
        lastSnapshottedRichTextJson: null,
        sinceLastSnapshot: null,
        trigger: HistorySnapshotTrigger.documentClose,
      );

      expect(decision.shouldSnapshot, isFalse);
      expect(decision.skipReason, HistorySnapshotSkip.identicalContent);
    });
  });

  group('HistorySnapshotPolicy — autosave pacing', () {
    test('the autosave interval is exactly 60 seconds', () {
      // A named constant, not a literal scattered through the editor.
      expect(
        HistorySnapshotPolicy.autosaveSnapshotInterval,
        const Duration(seconds: 60),
      );
    });

    test('a changed autosave inside the interval is refused', () {
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _edited,
        lastSnapshottedRichTextJson: _stored,
        sinceLastSnapshot: const Duration(seconds: 30),
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(decision.shouldSnapshot, isFalse);
      expect(decision.skipReason, HistorySnapshotSkip.withinInterval);
    });

    test('a changed autosave is allowed once the interval has elapsed', () {
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _edited,
        lastSnapshottedRichTextJson: _stored,
        sinceLastSnapshot: HistorySnapshotPolicy.autosaveSnapshotInterval,
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(decision.shouldSnapshot, isTrue);
      expect(decision.skipReason, isNull);
    });

    test('the interval boundary is inclusive', () {
      // One tick short of the interval is refused; exactly the interval is not.
      const policy = HistorySnapshotPolicy();

      expect(
        policy
            .evaluate(
              newRichTextJson: _edited,
              lastSnapshottedRichTextJson: _stored,
              sinceLastSnapshot: const Duration(seconds: 59, milliseconds: 999),
              trigger: HistorySnapshotTrigger.autosave,
            )
            .shouldSnapshot,
        isFalse,
      );
      expect(
        policy
            .evaluate(
              newRichTextJson: _edited,
              lastSnapshottedRichTextJson: _stored,
              sinceLastSnapshot: const Duration(seconds: 60),
              trigger: HistorySnapshotTrigger.autosave,
            )
            .shouldSnapshot,
        isTrue,
      );
    });

    test('a changed autosave with no prior snapshot is allowed', () {
      // sinceLastSnapshot == null means "never snapshotted", so the interval
      // cap cannot apply and the first real edit is captured.
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _edited,
        lastSnapshottedRichTextJson: null,
        sinceLastSnapshot: null,
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(decision.shouldSnapshot, isTrue);
      expect(decision.skipReason, isNull);
    });
  });

  group('HistorySnapshotPolicy — close/switch trigger', () {
    test(
      'a close/switch snapshots changed content even inside the interval',
      () {
        // The whole point of the close trigger: leaving a document must never
        // lose an edit just because the 60s pacing window has not closed.
        const policy = HistorySnapshotPolicy();
        final decision = policy.evaluate(
          newRichTextJson: _edited,
          lastSnapshottedRichTextJson: _stored,
          sinceLastSnapshot: Duration.zero,
          trigger: HistorySnapshotTrigger.documentClose,
        );

        expect(decision.shouldSnapshot, isTrue);
        expect(decision.skipReason, isNull);
      },
    );

    test(
      'a close/switch snapshots regardless of how recent the last one was',
      () {
        const policy = HistorySnapshotPolicy();
        final decision = policy.evaluate(
          newRichTextJson: _edited,
          lastSnapshottedRichTextJson: _stored,
          sinceLastSnapshot: const Duration(milliseconds: 1),
          trigger: HistorySnapshotTrigger.documentClose,
        );

        expect(decision.shouldSnapshot, isTrue);
      },
    );
  });

  group('HistorySnapshotPolicy — seeded on load', () {
    test('the first save after opening a document is not a duplicate', () {
      // Load seeds lastSnapshotted = the stored content. The first autosave
      // carries that same content, so it must be recognised as unchanged
      // rather than written as a fresh revision.
      const policy = HistorySnapshotPolicy();
      final seeded = _stored; // what _loadContent seeds from the open document

      final firstSave = policy.evaluate(
        newRichTextJson: seeded,
        lastSnapshottedRichTextJson: seeded,
        sinceLastSnapshot: null,
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(firstSave.shouldSnapshot, isFalse);
      expect(firstSave.skipReason, HistorySnapshotSkip.identicalContent);
    });

    test('a real edit right after opening is still captured', () {
      // Seeding must not swallow the author's first actual edit.
      const policy = HistorySnapshotPolicy();
      final decision = policy.evaluate(
        newRichTextJson: _edited,
        lastSnapshottedRichTextJson: _stored,
        sinceLastSnapshot: null,
        trigger: HistorySnapshotTrigger.autosave,
      );

      expect(decision.shouldSnapshot, isTrue);
    });
  });
}
