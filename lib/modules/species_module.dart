import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';
import 'package:lore_keeper/widgets/species_details_edit_dialog.dart';
import 'package:lore_keeper/widgets/species_wiki_article.dart';

/// Species Module - Right Panel Only (Wiki Article)
/// The tree/list is in the second column via SpeciesTree widget
class SpeciesModule extends StatelessWidget {
  final SpeciesProvider speciesProvider;

  const SpeciesModule({super.key, required this.speciesProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: speciesProvider,
      builder: (context, _) {
        final selectedNode = speciesProvider.selectedNode;

        if (selectedNode == null) {
          return _buildEmptyState(context);
        }

        return _buildArticleView(context, selectedNode);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.pawPrint,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a species to view its article',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Or create a new species using the list on the left',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleView(BuildContext context, ClassificationNode node) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = speciesProvider.getClassificationPath(node.id);

    final wikiData = SpeciesWikiData(
      id: node.id,
      name: node.name,
      scientificName:
          node.scientificName ??
          (node.isSpeciesOrSubspecies ? node.name : null),
      description: node.content.isNotEmpty
          ? node.content
          : 'No description available.',
      status: node.status.isNotEmpty
          ? node.status
          : (node.isSpeciesOrSubspecies ? 'Extant' : 'Group'),
      origin: node.origin,
      classificationPath: path.map((n) => n.name).toList(),
      classification: ClassificationData(
        lineage: path.isNotEmpty && path.length > 1
            ? path[path.length - 2].name
            : 'Unknown',
        kingdom: _findRankNode(path, 'kingdom')?.name ?? 'Unknown',
        phylum: _findRankNode(path, 'phylum')?.name ?? 'Unknown',
        className: _findRankNode(path, 'classRank')?.name ?? 'Unknown',
        order: _findRankNode(path, 'order')?.name ?? 'Unknown',
        family: _findRankNode(path, 'family')?.name ?? 'Unknown',
        genus: _findRankNode(path, 'genus')?.name ?? 'Unknown',
        species: node.isSpeciesOrSubspecies ? node.name : 'Unknown',
      ),
      characteristics: CharacteristicsData(
        averageLifespan: node.averageLifespan.isNotEmpty
            ? node.averageLifespan
            : 'Unknown',
        averageHeight: node.averageHeight.isNotEmpty
            ? node.averageHeight
            : 'Unknown',
        reproduction: node.reproduction.isNotEmpty
            ? node.reproduction
            : 'Unknown',
        diet: node.diet.isNotEmpty ? node.diet : 'Unknown',
        sentience: node.sentience.isNotEmpty
            ? node.sentience
            : (node.isSpeciesOrSubspecies ? 'Sapient' : 'Non-sapient'),
        population: node.population,
      ),
      overview: node.content.isNotEmpty ? node.content : null,
      physiology: node.physiology.isNotEmpty ? node.physiology : null,
      relatedEntities: [],
      backlinks: [],
    );

    // Outer box keeps the article away from the module edges; the article
    // content inside carries its own internal padding.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: SpeciesWikiArticle(
          data: wikiData,
          onEdit: () => SpeciesDetailsEditDialog.show(
            context,
            speciesProvider: speciesProvider,
            node: node,
          ),
        ),
      ),
    );
  }

  ClassificationNode? _findRankNode(
    List<ClassificationNode> path,
    String rank,
  ) {
    for (final node in path) {
      if (node.rank == rank) return node;
    }
    return null;
  }
}
