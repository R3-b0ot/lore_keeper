import 'package:flutter/material.dart';

// Mock data structure for Species Wiki Article - easy backend integration
// TODO: Replace with actual data from SpeciesProvider
// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

class SpeciesWikiData {
  final String id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;
  final String status; // Extant, Extinct, etc.
  final String? origin; // Planet/Location
  final List<String> classificationPath; // Breadcrumb path
  final ClassificationData classification;
  final CharacteristicsData characteristics;
  final String? overview;
  final String? physiology;
  final List<TimelineEvent> history;
  final List<RelatedEntity> relatedEntities;
  final List<String> galleryImages;
  final List<String> backlinks;

  const SpeciesWikiData({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    this.status = 'Extant',
    this.origin,
    this.classificationPath = const [],
    required this.classification,
    required this.characteristics,
    this.overview,
    this.physiology,
    this.history = const [],
    this.relatedEntities = const [],
    this.galleryImages = const [],
    this.backlinks = const [],
  });

  // Sample data for preview
  static SpeciesWikiData get sample => SpeciesWikiData(
    id: '1',
    name: 'Human',
    scientificName: 'Homo sapiens',
    description:
        'A highly intelligent, sapient species originating from Earth. Characterized by their adaptability, social complexity, and advanced technological development.',
    imageUrl: null,
    status: 'Extant',
    origin: 'Earth',
    classificationPath: ['Fauna', 'Terran Life', 'Animalia', 'Chordata'],
    classification: const ClassificationData(
      lineage: 'Terran Life',
      kingdom: 'Animalia',
      phylum: 'Chordata',
      className: 'Mammalia',
      order: 'Primates',
      family: 'Hominidae',
      genus: 'Homo',
      species: 'Homo sapiens',
    ),
    characteristics: const CharacteristicsData(
      averageLifespan: '70–120 years',
      averageHeight: '150–200 cm',
      reproduction: 'Sexual',
      diet: 'Omnivorous',
      sentience: 'Sapient',
      population: '~14 Billion',
    ),
    overview:
        'Humans are a bipedal primate belonging to the mammalian class. Known for their highly developed brains, capable of abstract reasoning, language, introspection, and problem solving.',
    physiology:
        'Human bodies exhibit substantial sexual dimorphism in mass and body composition. The defining physiological trait is the central nervous system.',
    history: const [
      TimelineEvent(
        date: '~300,000 BCE',
        title: 'Anatomically Modern Humans',
        description:
            'First appearance of Homo sapiens in the fossil record on Earth.',
      ),
      TimelineEvent(
        date: 'Year 2025 CE',
        title: 'First Human Divergence',
        description:
            'Initial milestones in genetic editing lead to minor but heritable metabolic improvements.',
      ),
      TimelineEvent(
        date: 'Year 2078 CE',
        title: 'Cybernetic Integration Begins',
        description:
            'Commercial availability of neural-interfaces creates the first true cyborgs.',
      ),
      TimelineEvent(
        date: 'Year 2194 CE',
        title: 'The Human Species Divide',
        description:
            'Formal taxonomic recognition of Homo cyberneticus as a distinct descendant species.',
      ),
    ],
    relatedEntities: const [
      RelatedEntity(
        name: 'Homo cyberneticus',
        type: 'Descendant Species',
        iconName: 'dna',
      ),
      RelatedEntity(
        name: 'Homo neanderthalensis',
        type: 'Ancestor / Related',
        iconName: 'dna',
      ),
      RelatedEntity(
        name: 'Synthetic Intelligence',
        type: 'Created By / Rival',
        iconName: 'cpu',
      ),
    ],
    galleryImages: [],
    backlinks: const [
      'The Fall of Earth',
      'First Contact Protocol',
      'The Cybernetic Age',
    ],
  );
}

class ClassificationData {
  final String lineage;
  final String kingdom;
  final String phylum;
  final String className;
  final String order;
  final String family;
  final String genus;
  final String species;

  const ClassificationData({
    required this.lineage,
    required this.kingdom,
    required this.phylum,
    required this.className,
    required this.order,
    required this.family,
    required this.genus,
    required this.species,
  });
}

class CharacteristicsData {
  final String averageLifespan;
  final String averageHeight;
  final String reproduction;
  final String diet;
  final String sentience;
  final String? population;

  const CharacteristicsData({
    required this.averageLifespan,
    required this.averageHeight,
    required this.reproduction,
    required this.diet,
    required this.sentience,
    this.population,
  });
}

class TimelineEvent {
  final String date;
  final String title;
  final String description;

  const TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
  });
}

class RelatedEntity {
  final String name;
  final String type;
  final String iconName;

  const RelatedEntity({
    required this.name,
    required this.type,
    required this.iconName,
  });
}

// Main Widget: Species Wiki Article
class SpeciesWikiArticle extends StatelessWidget {
  final SpeciesWikiData? data;

  /// Invoked when the user taps the Edit button in the article header.
  /// When null, the button is hidden (e.g. sample preview mode).
  final VoidCallback? onEdit;

  const SpeciesWikiArticle({super.key, this.data, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final speciesData = data ?? SpeciesWikiData.sample;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return _DesktopLayout(speciesData: speciesData, onEdit: onEdit);
        } else {
          return _MobileLayout(speciesData: speciesData, onEdit: onEdit);
        }
      },
    );
  }
}

// Desktop Layout: 2-column (8 cols content, 4 cols infoboxes)
class _DesktopLayout extends StatelessWidget {
  final SpeciesWikiData speciesData;
  final VoidCallback? onEdit;

  const _DesktopLayout({required this.speciesData, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Article Content (~2/3)
        Expanded(
          flex: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _ArticleContent(speciesData: speciesData, onEdit: onEdit),
          ),
        ),
        // Right Column: Infoboxes (~1/3, sticky)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: _StickyInfoboxes(speciesData: speciesData),
            ),
          ),
        ),
      ],
    );
  }
}

// Mobile Layout: Stacked vertically
class _MobileLayout extends StatelessWidget {
  final SpeciesWikiData speciesData;
  final VoidCallback? onEdit;

  const _MobileLayout({required this.speciesData, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _ArticleContent(speciesData: speciesData, onEdit: onEdit),
          const SizedBox(height: 24),
          _StickyInfoboxes(speciesData: speciesData),
        ],
      ),
    );
  }
}

// Private Widget: Sticky Infobox Column
class _StickyInfoboxes extends StatelessWidget {
  final SpeciesWikiData speciesData;

  const _StickyInfoboxes({required this.speciesData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClassificationInfobox(classification: speciesData.classification),
        const SizedBox(height: 16),
        _OriginInfobox(origin: speciesData.origin),
      ],
    );
  }
}

// Private Widget: Article Content Column
class _ArticleContent extends StatelessWidget {
  final SpeciesWikiData speciesData;
  final VoidCallback? onEdit;

  const _ArticleContent({required this.speciesData, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BreadcrumbNav(path: speciesData.classificationPath),
        const SizedBox(height: 24),
        _ArticleHeader(
          name: speciesData.name,
          scientificName: speciesData.scientificName,
          description: speciesData.description,
          imageUrl: speciesData.imageUrl,
          status: speciesData.status,
          onEdit: onEdit,
        ),
        const SizedBox(height: 32),
        if (speciesData.overview != null) ...[
          _OverviewSection(overview: speciesData.overview!),
          const SizedBox(height: 32),
        ],
        _CharacteristicsGrid(characteristics: speciesData.characteristics),
        const SizedBox(height: 32),
        if (speciesData.physiology != null) ...[
          _PhysiologySection(physiology: speciesData.physiology!),
          const SizedBox(height: 32),
        ],
        if (speciesData.history.isNotEmpty) ...[
          _TimelineSection(events: speciesData.history),
          const SizedBox(height: 32),
        ],
        if (speciesData.relatedEntities.isNotEmpty) ...[
          _RelationshipsSection(entities: speciesData.relatedEntities),
          const SizedBox(height: 32),
        ],
        if (speciesData.galleryImages.isNotEmpty) ...[
          _GallerySection(images: speciesData.galleryImages),
          const SizedBox(height: 32),
        ],
        if (speciesData.backlinks.isNotEmpty) ...[
          _BacklinksSection(backlinks: speciesData.backlinks),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// Private Widget: Breadcrumb Navigation
class _BreadcrumbNav extends StatelessWidget {
  final List<String> path;

  const _BreadcrumbNav({required this.path});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < path.length; i++) ...[
            _BreadcrumbItem(
              label: path[i],
              isLast: i == path.length - 1,
              isClickable: i < path.length - 1,
            ),
            if (i < path.length - 1) const _BreadcrumbSeparator(),
          ],
          if (path.isNotEmpty) ...[
            const _BreadcrumbSeparator(),
            Text(
              'Homo sapiens',
              style: TextStyle(
                color: _LoreColors.heading,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final bool isLast;
  final bool isClickable;

  const _BreadcrumbItem({
    required this.label,
    required this.isLast,
    required this.isClickable,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLast ? _LoreColors.heading : _LoreColors.muted;
    final cursor = isClickable ? SystemMouseCursors.click : MouseCursor.defer;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: isClickable ? () {} : null,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '/',
        style: TextStyle(color: _LoreColors.border, fontSize: 14),
      ),
    );
  }
}

// Private Widget: Article Header
class _ArticleHeader extends StatelessWidget {
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;
  final String status;
  final VoidCallback? onEdit;

  const _ArticleHeader({
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    required this.status,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges + Edit action
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    icon: 'dna',
                    label: 'Species',
                    color: _LoreColors.accent,
                  ),
                  _Badge(
                    icon: 'globe',
                    label: 'Terran Life',
                    color: Colors.green.shade400,
                  ),
                  _Badge(label: status, isPlain: true),
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 12),
              _EditButton(onPressed: onEdit!),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          scientificName ?? name,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _LoreColors.heading,
            letterSpacing: -0.5,
          ),
        ),
        if (scientificName != null) ...[
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              color: _LoreColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (description != null)
          Text(
            description!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade300,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String? icon;
  final String label;
  final Color? color;
  final bool isPlain;

  const _Badge({
    this.icon,
    required this.label,
    this.color,
    this.isPlain = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlain) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _LoreColors.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _LoreColors.border),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _LoreColors.muted,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final badgeColor = color ?? _LoreColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(_LucideIcons.getIcon(icon!), size: 12, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widget: Edit Details Button
class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Edit species details',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _LoreColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _LoreColors.accent.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _LucideIcons.getIcon('pencil_simple'),
                  size: 14,
                  color: _LoreColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: _LoreColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Private Widget: Overview Section
class _OverviewSection extends StatelessWidget {
  final String overview;

  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'book_open',
      title: 'Overview',
      child: Text(
        overview,
        style: TextStyle(color: _LoreColors.text, height: 1.7, fontSize: 15),
      ),
    );
  }
}

// Private Widget: Characteristics Grid
class _CharacteristicsGrid extends StatelessWidget {
  final CharacteristicsData characteristics;

  const _CharacteristicsGrid({required this.characteristics});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'list_checks',
      title: 'Characteristics',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _CharacteristicCard(
            label: 'Average Lifespan',
            value: characteristics.averageLifespan,
          ),
          _CharacteristicCard(
            label: 'Average Height',
            value: characteristics.averageHeight,
          ),
          _CharacteristicCard(
            label: 'Reproduction',
            value: characteristics.reproduction,
          ),
          _CharacteristicCard(label: 'Diet', value: characteristics.diet),
          _CharacteristicCard(
            label: 'Sentience',
            value: characteristics.sentience,
            valueColor: Colors.green.shade400,
          ),
          if (characteristics.population != null)
            _CharacteristicCard(
              label: 'Population',
              value: characteristics.population!,
            ),
        ],
      ),
    );
  }
}

class _CharacteristicCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CharacteristicCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoreColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LoreColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: _LoreColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? _LoreColors.heading,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Private Widget: Physiology Section
class _PhysiologySection extends StatelessWidget {
  final String physiology;

  const _PhysiologySection({required this.physiology});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'heart_pulse',
      title: 'Physiology',
      child: Text(
        physiology,
        style: TextStyle(color: _LoreColors.text, height: 1.7, fontSize: 15),
      ),
    );
  }
}

// Private Widget: Timeline Section
class _TimelineSection extends StatelessWidget {
  final List<TimelineEvent> events;

  const _TimelineSection({required this.events});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'history',
      title: 'History',
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++) ...[
            _TimelineEventItem(
              event: events[i],
              isLast: i == events.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineEventItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineEventItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _LoreColors.panel,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLast ? _LoreColors.accent : _LoreColors.border,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: _LoreColors.border)),
            ],
          ),
          const SizedBox(width: 16),
          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _LoreColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _LoreColors.heading,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: _LoreColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widget: Relationships Section
class _RelationshipsSection extends StatelessWidget {
  final List<RelatedEntity> entities;

  const _RelationshipsSection({required this.entities});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'network',
      title: 'Related Entities',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: entities
            .map((entity) => _RelatedEntityCard(entity: entity))
            .toList(),
      ),
    );
  }
}

class _RelatedEntityCard extends StatelessWidget {
  final RelatedEntity entity;

  const _RelatedEntityCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _LoreColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _LoreColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _LoreColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _LucideIcons.getIcon(entity.iconName),
              color: _LoreColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _LoreColors.heading,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entity.type,
                  style: TextStyle(fontSize: 11, color: _LoreColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widget: Gallery Section
class _GallerySection extends StatelessWidget {
  final List<String> images;

  const _GallerySection({required this.images});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      icon: 'image',
      title: 'Gallery',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: images
            .map(
              (url) => Container(
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _LoreColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _LoreColors.border),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: _LoreColors.muted),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// Private Widget: Backlinks Section
class _BacklinksSection extends StatelessWidget {
  final List<String> backlinks;

  const _BacklinksSection({required this.backlinks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Divider(color: _LoreColors.border.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'Mentioned In',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _LoreColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: backlinks
              .map(
                (link) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _LoreColors.panel,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _LoreColors.border),
                  ),
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 13, color: _LoreColors.text),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// Private Widget: Section Wrapper
class _SectionWrapper extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;

  const _SectionWrapper({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _LucideIcons.getIcon(icon),
              color: _LoreColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _LoreColors.heading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

// Private Widget: Classification Infobox
class _ClassificationInfobox extends StatelessWidget {
  final ClassificationData classification;

  const _ClassificationInfobox({required this.classification});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _LoreColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1e2b),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(bottom: BorderSide(color: _LoreColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CLASSIFICATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _LoreColors.heading,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  _LucideIcons.getIcon('tree_structure'),
                  color: _LoreColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ClassificationRow(
                  label: 'Lineage',
                  value: classification.lineage,
                ),
                _ClassificationRow(
                  label: 'Kingdom',
                  value: classification.kingdom,
                ),
                _ClassificationRow(
                  label: 'Phylum',
                  value: classification.phylum,
                ),
                _ClassificationRow(
                  label: 'Class',
                  value: classification.className,
                ),
                _ClassificationRow(label: 'Order', value: classification.order),
                _ClassificationRow(
                  label: 'Family',
                  value: classification.family,
                ),
                _ClassificationRow(label: 'Genus', value: classification.genus),
                _ClassificationRow(
                  label: 'Species',
                  value: classification.species,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassificationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _ClassificationRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHighlighted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _LoreColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _LoreColors.accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: _LoreColors.muted),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _LoreColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: _LoreColors.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _LoreColors.heading,
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widget: Origin Infobox
class _OriginInfobox extends StatelessWidget {
  final String? origin;

  const _OriginInfobox({this.origin});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _LoreColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1e2b),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(bottom: BorderSide(color: _LoreColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORIGIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _LoreColors.heading,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  _LucideIcons.getIcon('globe'),
                  color: _LoreColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (origin != null) ...[
                  Text(
                    'Originated On',
                    style: TextStyle(
                      fontSize: 11,
                      color: _LoreColors.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _LucideIcons.getIcon('globe_hemisphere_west'),
                          color: Colors.blue.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          origin!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _LoreColors.heading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Creator / Progenitor',
                    style: TextStyle(
                      fontSize: 11,
                      color: _LoreColors.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      'Natural Evolution',
                      style: TextStyle(
                        fontSize: 13,
                        color: _LoreColors.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Color Constants matching the HTML spec
class _LoreColors {
  static const Color panel = Color(0xFF151822);
  static const Color border = Color(0xFF2A2E3D);
  static const Color text = Color(0xFFD1D5DB);
  static const Color heading = Color(0xFFF3F4F6);
  static const Color accent = Color(0xFF6366F1);
  static const Color muted = Color(0xFF9CA3AF);
}

// Lucide Icons mapping (using Icons from material for simplicity)
// In production, use lucide_icons or phosphor_flutter package
class _LucideIcons {
  static IconData getIcon(String name) {
    switch (name) {
      case 'folder':
        return Icons.folder_outlined;
      case 'dna':
        return Icons.biotech_outlined;
      case 'planet':
        return Icons.public;
      case 'book_open':
        return Icons.menu_book_outlined;
      case 'list_checks':
        return Icons.checklist;
      case 'heart_pulse':
        return Icons.favorite_outline;
      case 'history':
        return Icons.history;
      case 'network':
        return Icons.hub_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'tree_structure':
        return Icons.account_tree_outlined;
      case 'globe':
        return Icons.public;
      case 'globe_hemisphere_west':
        return Icons.language;
      case 'cpu':
        return Icons.memory;
      case 'pencil_simple':
        return Icons.edit_outlined;
      case 'dots_three':
        return Icons.more_horiz;
      default:
        return Icons.circle_outlined;
    }
  }
}
