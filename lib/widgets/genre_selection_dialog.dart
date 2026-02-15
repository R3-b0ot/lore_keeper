// lib/widgets/genre_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/theme/app_colors.dart';

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
  'Custom': ['User-Defined Genre'],
};

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

    if (widget.initialGenre.isNotEmpty) {
      _selectedGenre = widget.initialGenre;

      for (var category in _allGenres.keys) {
        if (_allGenres[category]!.contains(widget.initialGenre)) {
          _selectedCategory = category;
          return;
        }
      }

      _selectedCategory = 'Custom';
      _customGenreController.text = widget.initialGenre;
      _selectedGenre = 'User-Defined Genre';
    } else {
      _selectedGenre = _allGenres[_selectedCategory]!.first;
    }
  }

  @override
  void dispose() {
    _customGenreController.dispose();
    super.dispose();
  }

  void _selectGenre(String genre) {
    if (genre == 'User-Defined Genre' &&
        _customGenreController.text.trim().isNotEmpty) {
      Navigator.of(context).pop(_customGenreController.text.trim());
    } else if (genre != 'User-Defined Genre') {
      Navigator.of(context).pop(genre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.bgPanel
        : Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
              child: Row(
                children: [
                  Text(
                    'Select Genre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: onSurfaceColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    style: IconButton.styleFrom(
                      backgroundColor: onSurfaceColor.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Categories
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: onSurfaceColor.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _allGenres.keys.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                                if (category != 'Custom') {
                                  _selectedGenre = _allGenres[category]!.first;
                                } else {
                                  _selectedGenre = 'User-Defined Genre';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : onSurfaceColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Sub-genres
                  Expanded(
                    child: _selectedCategory == 'Custom'
                        ? _buildCustomInput(onSurfaceColor)
                        : _buildGenreList(onSurfaceColor),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreList(Color onSurfaceColor) {
    final genres = _allGenres[_selectedCategory] ?? [];
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1, // SQUARE CARDS
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final isSelected = _selectedGenre == genre;
        final imagePath = _getGenreImage(genre);

        return InkWell(
          onTap: () => _selectGenre(genre),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: onSurfaceColor.withValues(alpha: 0.1),
                      child: Icon(
                        LucideIcons.imageOff,
                        color: onSurfaceColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(
                            context,
                          ).colorScheme.scrim.withValues(alpha: 0.8),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Selection Glow (Inner)
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),

                  // Text Label
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          genre,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Theme.of(context).colorScheme.onSurface,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const Map<String, String> _genreImageMap = {
    // Fiction
    'Action and Adventure': 'action_adventure.png',
    'Classic': 'classic.png',
    'Contemporary': 'contemporary.png',
    'Crime and Mystery': 'crime_mystery.png',
    'Dystopian': 'dystopian.png',
    'Fantasy': 'fantasy.png',
    'Graphic Novel': 'graphic_novel.png',
    'Historical Fiction': 'historical_fiction.png',
    'Horror': 'horror.png',
    'Literary Fiction': 'literary_fiction.png',
    'Romance': 'romance.png',
    'Science Fiction': 'science_fiction.png',
    'Thriller': 'thriller.png',
    'Young Adult (YA)': 'young_adult.png',

    // Nonfiction
    'Autobiography and Memoir': 'autobiography_memoir.png',
    'Biography': 'biography.png',
    'Cookbooks': 'cookbooks.png',
    'Historical Nonfiction': 'historical_nonfiction.png',
    'How-to and DIY': 'howto_diy.png',
    'Humor': 'humor.png',
    'Self-Help': 'self_help.png',
    'Travel': 'travel.png',
    'True Crime': 'true_crime.png',

    // Custom
    'User-Defined Genre': 'custom_genre.png',
  };

  String _getGenreImage(String genre) {
    const basePath = 'assets/images/genres/';
    final fileName = _genreImageMap[genre] ?? 'crime_mystery.png';
    return '$basePath$fileName';
  }

  Widget _buildCustomInput(Color onSurfaceColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Genre',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customGenreController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Cyberpunk Western',
              filled: true,
              fillColor: onSurfaceColor.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
            onSubmitted: (_) => _selectGenre('User-Defined Genre'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _selectGenre('User-Defined Genre'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Apply Custom Genre'),
            ),
          ),
        ],
      ),
    );
  }
}
