/// Decides *when* a `ManuscriptDocument` history snapshot is written.
///
/// Cycle 3b, item 2 (MS-008 follow-up). This is the single place that answers
/// "should a history entry be written right now?" so the editor does not carry
/// the decision itself.
///
/// Why this exists: content autosave and history snapshots are different
/// concerns. Content must reach storage promptly and often (S-34: a ~2s
/// debounce), while a snapshot is a *revision record* — one entry per real
/// editing session beat, not one per debounce flush. Before this policy those
/// two were welded together in `ManuscriptEditor._saveContent`, so every
/// autosave wrote a history entry and the panel filled with near-identical
/// snapshots.
///
/// The rules, in priority order:
///
/// 1. **Never snapshot identical content.** A revision that stores the same
///    bytes is noise. This also covers the seeded-on-load case: `_loadContent`
///    seeds the baseline from the opened document, so the first autosave after
///    opening is recognised as unchanged.
/// 2. **Autosave is paced.** At most one snapshot per
///    [HistorySnapshotPolicy.autosaveSnapshotInterval].
/// 3. **Close/switch is never paced away.** Leaving a document always records
///    the change, so an edit cannot be lost because the 60s window was still
///    open.
///
/// Deliberately pure Dart — no Flutter UI imports, no Hive, no `dart:io`, and
/// no clock. The caller supplies the elapsed duration, which is what makes the
/// interval boundaries testable without waiting on real time.
library;

/// What prompted a save attempt.
enum HistorySnapshotTrigger {
  /// A debounced content autosave.
  autosave,

  /// The document is being closed or the editor is switching documents.
  documentClose,
}

/// Why a snapshot was refused. `null` means it was written.
enum HistorySnapshotSkip {
  /// The content is byte-identical to the last snapshot.
  identicalContent,

  /// An autosave arrived inside [HistorySnapshotPolicy.autosaveSnapshotInterval].
  withinInterval,
}

/// The outcome of one [HistorySnapshotPolicy.evaluate] call.
typedef HistorySnapshotDecision = ({
  bool shouldSnapshot,
  HistorySnapshotSkip? skipReason,
});

/// Pure, stateless snapshot pacing for manuscript documents.
class HistorySnapshotPolicy {
  const HistorySnapshotPolicy();

  /// How often an *autosave* may write a snapshot.
  ///
  /// A named constant rather than a literal so the pacing rule is one edit away
  /// and both the policy and its tests refer to the same value. Close/switch
  /// ignores it entirely (rule 3).
  static const Duration autosaveSnapshotInterval = Duration(seconds: 60);

  /// Whether a snapshot should be written for [newRichTextJson].
  ///
  /// [lastSnapshottedRichTextJson] is the content of the most recent snapshot —
  /// including the value seeded on load, so the first save of a freshly opened
  /// document is not mistaken for a revision. [sinceLastSnapshot] is how long
  /// ago that snapshot was taken, or `null` when there is no snapshot yet (in
  /// which case the interval cannot block the write).
  HistorySnapshotDecision evaluate({
    required String? newRichTextJson,
    required String? lastSnapshottedRichTextJson,
    required Duration? sinceLastSnapshot,
    required HistorySnapshotTrigger trigger,
  }) {
    // Rule 1 — identical content is never a revision, on any trigger.
    if (newRichTextJson == lastSnapshottedRichTextJson) {
      return (
        shouldSnapshot: false,
        skipReason: HistorySnapshotSkip.identicalContent,
      );
    }

    // Rule 2 — pace autosaves only.
    if (trigger == HistorySnapshotTrigger.autosave &&
        sinceLastSnapshot != null &&
        sinceLastSnapshot < autosaveSnapshotInterval) {
      return (
        shouldSnapshot: false,
        skipReason: HistorySnapshotSkip.withinInterval,
      );
    }

    // Rule 3 — changed content on close/switch always records.
    return (shouldSnapshot: true, skipReason: null);
  }
}
