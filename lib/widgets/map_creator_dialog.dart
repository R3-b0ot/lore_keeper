import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';

enum MapCreationType { flat, layered, import }

class MapCreatorDialog extends StatefulWidget {
  final MapListProvider mapProvider;

  const MapCreatorDialog({super.key, required this.mapProvider});

  @override
  State<MapCreatorDialog> createState() => _MapCreatorDialogState();
}

class _MapCreatorDialogState extends State<MapCreatorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  MapCreationType _selectedType = MapCreationType.flat;
  String? _selectedFilePath;
  String? _fileType;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    List<String> allowedExtensions;
    switch (_selectedType) {
      case MapCreationType.flat:
        allowedExtensions = ['jpg', 'jpeg', 'png'];
        break;
      case MapCreationType.layered:
        allowedExtensions = ['svg', 'eps'];
        break;
      case MapCreationType.import:
        // Future implementation
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _fileType = result.files.single.extension;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == MapCreationType.import) {
        // Future implementation - show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import from Realm Keeper - Coming Soon!'),
          ),
        );
        return;
      }

      if (_selectedFilePath != null) {
        final name = _nameController.text.trim();
        final key = await widget.mapProvider.createNewMap(
          name,
          _selectedFilePath!,
          _fileType!,
        );
        if (key != -1) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Map'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Map Name',
                hintText: 'Enter a name for the map',
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Map Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _selectedType = MapCreationType.flat),
                    icon: const Icon(Icons.image),
                    label: const Text('Flat Map\n(JPEG/PNG)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == MapCreationType.flat
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _selectedType == MapCreationType.flat
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _selectedType = MapCreationType.layered),
                    icon: const Icon(Icons.layers),
                    label: const Text('Layered Map\n(SVG/EPS)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == MapCreationType.layered
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _selectedType == MapCreationType.layered
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _selectedType = MapCreationType.import),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Import from\nRealm Keeper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == MapCreationType.import
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _selectedType == MapCreationType.import
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedType != MapCreationType.import) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedFilePath ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text('Browse'),
                  ),
                ],
              ),
              if (_fileType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('File type: $_fileType'),
                ),
            ] else ...[
              const Text(
                'Import functionality from Realm Keeper will be available in a future update.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _selectedType == MapCreationType.import ? 'Coming Soon' : 'Create',
          ),
        ),
      ],
    );
  }
}
