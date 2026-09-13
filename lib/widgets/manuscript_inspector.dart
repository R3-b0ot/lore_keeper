// lib/widgets/manuscript_inspector.dart
//
// Column 4 of the Manuscript Project Editor.
//
// Displays metadata, scene information, references, backlinks, and hierarchy
// for the currently selected ManuscriptDocument.
//
// Ownership (per spec §2.1 / §13):
//   - Receives the selected document from the parent (ManuscriptModule / shell).
//   - Resolves entity names via the canonical ReferenceNameResolver.
//   - Calls onDocumentSelected when a backlink is activated so the shell's
//     canonical selection path is used (never mutates private state).
//   - Does NOT own Binder, Corkboard, Outliner, Collections, or any navigation.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/services/manuscript_reference_service.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';

/// Canonical key for widget-test topology assertions (spec §5.2).
const Key kManuscriptInspectorKey = Key('manuscript-inspector');

/// Column 4 — Manuscript Inspector.
///
/// Receives the [selectedDocument] from the parent and renders all metadata,
/// scene information, hierarchy, outgoing references, and backlinks.
///
/// When a backlink navigation is requested, [onDocumentSelected] is called
/// so the shell and Binder are kept in sync (spec §12 / P1-4 fix).
class ManuscriptInspector extends StatelessWidget {
  /// The document currently selected in Column 2 / shell state.
  /// Null when no document is active.
  final ManuscriptDocument? selectedDocument;

  /// The shared binder provider — used for hierarchy queries (parent title,
  /// children count, depth). Must be the same instance as Column 2.
  final ManuscriptBinderProvider? binderProvider;

  /// Canonical name resolver for resolving entity IDs to human-readable names.
  final ReferenceNameResolver nameResolver;

  /// Service for reading reference index entries for this document.
  /// May be null if the reference service has not yet been initialised.
  final ManuscriptReferenceService? referenceService;

  /// Project ID — needed for constructing EntityRef backlink queries.
  final int projectId;

  /// Callback to navigate to another document via a backlink.
  ///
  /// Must be wired to the shell's canonical selection update so that the
  /// Binder, editor, and inspector all stay in sync (spec §12).
  final ValueChanged<String>? onDocumentSelected;

  const ManuscriptInspector({
    super.key,
    required this.selectedDocument,
    required this.binderProvider,
    required this.nameResolver,
    required this.referenceService,
    required this.projectId,
    this.onDocumentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Empty state — no document selected.
    if (selectedDocument == null) {
      return Container(
        key: kManuscriptInspectorKey,
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.info,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a document',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspector shows metadata,\nreferences, and links',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doc = selectedDocument!;

    return Container(
      key: kManuscriptInspectorKey,
      color: cs.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(
                  _iconForType(doc.documentType),
                  size: 20,
                  color: _colorForType(doc.documentType, cs),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inspector',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Document metadata ───────────────────────────────
                  _InspectorSection(
                    title: 'Document',
                    children: [
                      _InspectorRow('Type', doc.documentType.label),
                      _InspectorRow('Status', doc.status.label),
                      _InspectorRow('Words', '${doc.wordCount}'),
                      _InspectorRow('Characters', '${doc.characterCount}'),
                      if (doc.createdAt != null)
                        _InspectorRow('Created', _formatDate(doc.createdAt!)),
                      if (doc.modifiedAt != null)
                        _InspectorRow('Modified', _formatDate(doc.modifiedAt!)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Scene metadata (leaves only) ─────────────────────
                  if (doc.isLeaf) ...[
                    _InspectorSection(
                      title: 'Scene Metadata',
                      children: [
                        _InspectorRow(
                          'POV Character',
                          _resolveOrRaw(
                            doc.povCharacterId,
                            EntityType.character,
                          ),
                          isUnresolved: doc.povCharacterId != null &&
                              nameResolver.resolveById(
                                    doc.povCharacterId!,
                                    EntityType.character,
                                  ) ==
                                  null,
                        ),
                        _InspectorRow(
                          'Location',
                          doc.locationId ?? '—',
                        ),
                        _InspectorRow(
                          'Timeline',
                          _resolveOrRaw(
                            doc.timelineEventId,
                            EntityType.timelineEvent,
                          ),
                          isUnresolved: doc.timelineEventId != null &&
                              nameResolver.resolveById(
                                    doc.timelineEventId!,
                                    EntityType.timelineEvent,
                                  ) ==
                                  null,
                        ),
                        _InspectorRow(
                          'Plotline',
                          doc.plotline ?? '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Characters ───────────────────────────────────────
                  if (doc.characterIds.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Characters (${doc.characterIds.length})',
                      children: doc.characterIds
                          .map(
                            (id) => _InspectorRow(
                              '•',
                              _resolveOrRaw(id, EntityType.character),
                              isUnresolved:
                                  nameResolver.resolveById(
                                        id,
                                        EntityType.character,
                                      ) ==
                                      null,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Tags ─────────────────────────────────────────────
                  if (doc.tagIds.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Tags (${doc.tagIds.length})',
                      children: doc.tagIds
                          .map((id) => _InspectorRow('•', id))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Summary ──────────────────────────────────────────
                  if (doc.summary != null && doc.summary!.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Summary',
                      children: [_InspectorRow('', doc.summary!)],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Hierarchy ────────────────────────────────────────
                  if (binderProvider != null)
                    _InspectorSection(
                      title: 'Hierarchy',
                      children: [
                        _InspectorRow(
                          'Parent',
                          _parentTitle(doc) ?? 'Root',
                        ),
                        _InspectorRow(
                          'Children',
                          '${binderProvider!.getChildren(doc.id).length}',
                        ),
                        _InspectorRow(
                          'Depth',
                          '${_depth(doc.id)}',
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // ── References ───────────────────────────────────────
                  _buildReferencesSection(context, doc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── References / Backlinks ──────────────────────────────────────────────

  Widget _buildReferencesSection(
    BuildContext context,
    ManuscriptDocument doc,
  ) {
    if (referenceService == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final outgoingRefs = referenceService!.getReferencesFrom(doc);
    final docRef = EntityRef.fromKey(
      key: doc.id,
      entityType: 'ManuscriptDocument',
      projectId: projectId.toString(),
    );
    final backlinks = referenceService!.getBacklinksTo(docRef);

    if (outgoingRefs.isEmpty && backlinks.isEmpty) {
      return _InspectorSection(
        title: 'References',
        children: [const _InspectorRow('', 'No references found')],
      );
    }

    return _InspectorSection(
      title: 'References',
      children: [
        if (outgoingRefs.isNotEmpty) ...[
          Text(
            'References (${outgoingRefs.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...outgoingRefs.map(
            (ref) => _ReferenceTile(
              ref: ref,
              currentDocumentId: doc.id,
              nameResolver: nameResolver,
              onDocumentSelected: onDocumentSelected,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (backlinks.isNotEmpty) ...[
          Text(
            'Backlinks (${backlinks.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...backlinks.map(
            (ref) => _ReferenceTile(
              ref: ref,
              currentDocumentId: doc.id,
              nameResolver: nameResolver,
              onDocumentSelected: onDocumentSelected,
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Resolve entity ID to a display name; if no canonical source exists or the
  /// entity is not found, return an explicit unresolved label (spec §13.3).
  String _resolveOrRaw(String? id, String entityType) {
    if (id == null) return '—';
    final resolved = nameResolver.resolveById(id, entityType);
    if (resolved != null) return resolved;
    return 'Unresolved • $id';
  }

  String? _parentTitle(ManuscriptDocument doc) {
    if (doc.parentId == null || binderProvider == null) return null;
    return binderProvider!.getDocument(doc.parentId!)?.title;
  }

  int _depth(String documentId) {
    if (binderProvider == null) return 0;
    int depth = 0;
    String? currentId = documentId;
    while (currentId != null) {
      final doc = binderProvider!.getDocument(currentId);
      if (doc?.parentId == null) break;
      currentId = doc!.parentId;
      depth++;
    }
    return depth;
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static IconData _iconForType(ManuscriptDocumentType type) {
    return switch (type) {
      ManuscriptDocumentType.manuscript => LucideIcons.bookOpen,
      ManuscriptDocumentType.part => LucideIcons.folderKanban,
      ManuscriptDocumentType.chapter => LucideIcons.book,
      ManuscriptDocumentType.scene => LucideIcons.fileText,
      ManuscriptDocumentType.section => LucideIcons.folder,
      ManuscriptDocumentType.note => LucideIcons.stickyNote,
      ManuscriptDocumentType.research => LucideIcons.search,
      ManuscriptDocumentType.frontMatter => LucideIcons.fileInput,
      ManuscriptDocumentType.backMatter => LucideIcons.fileOutput,
      ManuscriptDocumentType.custom => LucideIcons.file,
    };
  }

  static Color _colorForType(ManuscriptDocumentType type, ColorScheme cs) {
    return switch (type) {
      ManuscriptDocumentType.manuscript => cs.primary,
      ManuscriptDocumentType.part => cs.tertiary,
      ManuscriptDocumentType.chapter => cs.secondary,
      ManuscriptDocumentType.scene => cs.primary,
      ManuscriptDocumentType.section => cs.tertiary,
      ManuscriptDocumentType.note => Colors.amber,
      ManuscriptDocumentType.research => Colors.blue,
      ManuscriptDocumentType.frontMatter => Colors.purple,
      ManuscriptDocumentType.backMatter => Colors.purple,
      ManuscriptDocumentType.custom => cs.outline,
    };
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────────

/// A single reference tile in the outgoing/backlink list.
///
/// When tapped on a backlink to another ManuscriptDocument, calls
/// [onDocumentSelected] so the shell's canonical selection is updated (spec §12).
class _ReferenceTile extends StatelessWidget {
  final ReferenceIndexEntry ref;
  final String currentDocumentId;
  final ReferenceNameResolver nameResolver;
  final ValueChanged<String>? onDocumentSelected;

  const _ReferenceTile({
    required this.ref,
    required this.currentDocumentId,
    required this.nameResolver,
    required this.onDocumentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isOutgoing = ref.source.id == currentDocumentId;
    final resolvedName = nameResolver.resolve(ref.target);
    final isUnresolved = resolvedName == null;
    final displayName = resolvedName ?? ref.target.id;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isOutgoing ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
        size: 16,
        color: isOutgoing ? cs.primary : cs.secondary,
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: isUnresolved ? FontStyle.italic : FontStyle.normal,
          color: isUnresolved ? cs.onSurfaceVariant : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUnresolved) ...[
            Icon(LucideIcons.alertTriangle, size: 12, color: cs.error),
            const SizedBox(width: 4),
            Text(
              'Unresolved • ',
              style: theme.textTheme.labelSmall?.copyWith(color: cs.error),
            ),
          ],
          Text(
            '${ref.target.entityType} • ${ref.kind}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: () {
        // Backlink navigation — call the shell callback so Column 2 stays in sync.
        if (!isOutgoing &&
            ref.source.entityType == 'ManuscriptDocument' &&
            onDocumentSelected != null) {
          onDocumentSelected!(ref.source.id);
        }
      },
    );
  }
}

/// A collapsible section within the Inspector.
class _InspectorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InspectorSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

/// A label–value row inside an Inspector section.
class _InspectorRow extends StatelessWidget {
  final String label;
  final String value;

  /// Whether the value represents an unresolved entity reference.
  /// When true the value is rendered in italic with a warning colour.
  final bool isUnresolved;

  const _InspectorRow(this.label, this.value, {this.isUnresolved = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
          Expanded(
            child: Row(
              children: [
                if (isUnresolved) ...[
                  Icon(LucideIcons.alertTriangle, size: 12, color: cs.error),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle:
                          isUnresolved ? FontStyle.italic : FontStyle.normal,
                      color: isUnresolved ? cs.error : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
