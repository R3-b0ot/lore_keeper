import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';

/// Dialog for editing every species detail displayed in the wiki article.
///
/// Covers identity (name, scientific name, status, origin), long-form
/// content (description, physiology) and the characteristics grid.
class SpeciesDetailsEditDialog extends StatefulWidget {
  final SpeciesProvider speciesProvider;
  final ClassificationNode node;

  const SpeciesDetailsEditDialog({
    super.key,
    required this.speciesProvider,
    required this.node,
  });

  /// Convenience helper to show the dialog and persist on save.
  static Future<void> show(
    BuildContext context, {
    required SpeciesProvider speciesProvider,
    required ClassificationNode node,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => SpeciesDetailsEditDialog(
        speciesProvider: speciesProvider,
        node: node,
      ),
    );
  }

  @override
  State<SpeciesDetailsEditDialog> createState() =>
      _SpeciesDetailsEditDialogState();
}

class _SpeciesDetailsEditDialogState extends State<SpeciesDetailsEditDialog> {
  static const _statusOptions = [
    'Extant',
    'Extinct',
    'Endangered',
    'Mythical',
    'Unknown',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _scientificNameController;
  late final TextEditingController _originController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _physiologyController;
  late final TextEditingController _lifespanController;
  late final TextEditingController _heightController;
  late final TextEditingController _reproductionController;
  late final TextEditingController _dietController;
  late final TextEditingController _sentienceController;
  late final TextEditingController _populationController;
  late String _status;

  @override
  void initState() {
    super.initState();
    final node = widget.node;
    _nameController = TextEditingController(text: node.name);
    _scientificNameController = TextEditingController(
      text: node.scientificName ?? '',
    );
    _originController = TextEditingController(text: node.origin ?? '');
    _descriptionController = TextEditingController(text: node.content);
    _physiologyController = TextEditingController(text: node.physiology);
    _lifespanController = TextEditingController(text: node.averageLifespan);
    _heightController = TextEditingController(text: node.averageHeight);
    _reproductionController = TextEditingController(text: node.reproduction);
    _dietController = TextEditingController(text: node.diet);
    _sentienceController = TextEditingController(text: node.sentience);
    _populationController = TextEditingController(text: node.population ?? '');
    _status = _statusOptions.contains(node.status) ? node.status : 'Extant';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    _physiologyController.dispose();
    _lifespanController.dispose();
    _heightController.dispose();
    _reproductionController.dispose();
    _dietController.dispose();
    _sentienceController.dispose();
    _populationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await widget.speciesProvider.updateNodeDetails(
        widget.node.id,
        name: _nameController.text,
        scientificName: _scientificNameController.text,
        status: _status,
        origin: _originController.text,
        description: _descriptionController.text,
        physiology: _physiologyController.text,
        averageLifespan: _lifespanController.text,
        averageHeight: _heightController.text,
        reproduction: _reproductionController.text,
        diet: _dietController.text,
        sentience: _sentienceController.text,
        population: _populationController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.pencilLine, size: 22, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Edit Species Details')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 480, maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IDENTITY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(LucideIcons.tag, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scientificNameController,
                decoration: const InputDecoration(
                  labelText: 'Scientific Name',
                  hintText: 'e.g. Homo sapiens',
                  prefixIcon: Icon(LucideIcons.dna, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(LucideIcons.activity, size: 18),
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'Extant'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        hintText: 'Planet / location',
                        prefixIcon: Icon(LucideIcons.globe, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'CONTENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description / Overview',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(LucideIcons.bookOpen, size: 18),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _physiologyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Physiology',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(LucideIcons.heartPulse, size: 18),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'CHARACTERISTICS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lifespanController,
                      decoration: const InputDecoration(
                        labelText: 'Avg. Lifespan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Avg. Height',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reproductionController,
                      decoration: const InputDecoration(
                        labelText: 'Reproduction',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dietController,
                      decoration: const InputDecoration(
                        labelText: 'Diet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sentienceController,
                      decoration: const InputDecoration(
                        labelText: 'Sentience',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _populationController,
                      decoration: const InputDecoration(
                        labelText: 'Population',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _nameController.text.trim().isEmpty ? null : _save,
          icon: const Icon(LucideIcons.check, size: 18),
          label: const Text('Save Details'),
        ),
      ],
    );
  }
}
