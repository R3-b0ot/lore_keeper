// lib/widgets/genre_selection_dialog.dart

import 'package:flutter/material.dart';

// ----------------------------------------------------
// 1. GENRE DATA STRUCTURE
// ----------------------------------------------------

// Map to hold the main categories and their sub-genres
const Map<String, List<String>> _allGenres = {
  'Fiction': [
    'Action and Adventure',
    'Classic',
    'Contemporary',
    'Crime and Mystery',
    'Dystopian',
    'Fantasy',
    'Graphic Novel',
    'Historical Fiction',
    'Horror',
    'Literary Fiction',
    'Romance',
    'Science Fiction',
    'Thriller',
    'Young Adult (YA)',
  ],
  'Nonfiction': [
    'Autobiography and Memoir',
    'Biography',
    'Cookbooks',
    'Historical Nonfiction',
    'How-to and DIY',
    'Humor',
    'Self-Help',
    'Travel',
    'True Crime',
  ],
  'Custom': [
    'User-Defined Genre', // This is just a label for the input field
  ],
};

// ----------------------------------------------------
// 2. GENRE SELECTION DIALOG WIDGET
// ----------------------------------------------------

class GenreSelectionDialog extends StatefulWidget {
  final String initialGenre;

  const GenreSelectionDialog({super.key, required this.initialGenre});

  @override
  State<GenreSelectionDialog> createState() => _GenreSelectionDialogState();
}

class _GenreSelectionDialogState extends State<GenreSelectionDialog> {
  String _selectedCategory = _allGenres.keys.first;
  String? _selectedGenre;
  late TextEditingController _customGenreController;

  @override
  void initState() {
    super.initState();
    _customGenreController = TextEditingController();

    // Logic to determine initial selection
    if (widget.initialGenre.isNotEmpty) {
      _selectedGenre = widget.initialGenre;

      // Check if it's a standard genre
      for (var category in _allGenres.keys) {
        if (_allGenres[category]!.contains(widget.initialGenre)) {
          _selectedCategory = category;
          return; // Exit if found in standard list
        }
      }

      // If it's not a standard genre, assume it's custom
      _selectedCategory = 'Custom';
      _customGenreController.text = widget.initialGenre;
      _selectedGenre = 'User-Defined Genre'; // Set the label
    } else {
      // Default to the first sub-genre
      _selectedGenre = _allGenres[_selectedCategory]!.first;
    }
  }

  @override
  void dispose() {
    _customGenreController.dispose();
    super.dispose();
  }

  // Handles returning the genre, whether custom or predefined
  void _selectGenre(String genre) {
    if (genre == 'User-Defined Genre' &&
        _customGenreController.text.trim().isNotEmpty) {
      // Return the text from the input field for custom genre
      Navigator.of(context).pop(_customGenreController.text.trim());
    } else if (genre != 'User-Defined Genre') {
      // Return the predefined genre
      Navigator.of(context).pop(genre);
    }
    // Do nothing if custom genre is selected but the field is empty
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentGenres = _allGenres[_selectedCategory] ?? [];

    return AlertDialog(
      title: const Text('Select Project Genre'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN: Category List (Fiction/Nonfiction/Custom)
            SizedBox(
              width: 150,
              child: ListView(
                children: _allGenres.keys.map((category) {
                  return ListTile(
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight: _selectedCategory == category
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedCategory == category
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        // For non-custom categories, select the first genre
                        if (category != 'Custom') {
                          _selectedGenre = _allGenres[category]!.first;
                        } else {
                          // For custom category, select the input field label
                          _selectedGenre = 'User-Defined Genre';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const VerticalDivider(),

            // RIGHT COLUMN: Sub-Genre List or Custom Input
            Expanded(
              child: _selectedCategory == 'Custom'
                  // Custom Input Field
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Enter Custom Genre:'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customGenreController,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Solar Punk Fantasy',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const Spacer(),
                          // Separate button for custom genre confirmation
                          FilledButton(
                            onPressed: () => _selectGenre('User-Defined Genre'),
                            child: const Text('Confirm Custom Genre'),
                          ),
                        ],
                      ),
                    )
                  // Predefined Genre List
                  : ListView(
                      children: currentGenres.map((genre) {
                        return ListTile(
                          title: Text(genre),
                          tileColor: _selectedGenre == genre
                              ? Theme.of(context).primaryColor.withAlpha(26)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedGenre = genre;
                              _selectGenre(genre); // Select and close
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
