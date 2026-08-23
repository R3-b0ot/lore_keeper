import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/project_book/genre_glow.dart';
import 'package:lore_keeper/widgets/project_book/project_book.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ordered genre groups mirroring the prototype's `<select>` optgroups so the
/// demo can browse every palette the registry supports.
const Map<String, List<String>> _genreGroups = {
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

/// Builds the prototype's genre `<select>` as a dropdown whose disabled group
/// labels emulate `<optgroup>` headers. Shared by the demo and the assistant.
List<DropdownMenuItem<String>> _genreDropdownItems() {
  return [
    for (final group in _genreGroups.entries) ...[
      DropdownMenuItem<String>(
        enabled: false,
        value: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            group.key.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      for (final genre in group.value)
        DropdownMenuItem<String>(value: genre, child: Text(genre)),
    ],
  ];
}

class ProjectBookDemoScreen extends StatefulWidget {
  const ProjectBookDemoScreen({super.key});

  @override
  State<ProjectBookDemoScreen> createState() => _ProjectBookDemoScreenState();
}

class _ProjectBookDemoScreenState extends State<ProjectBookDemoScreen> {
  String _selectedGenre = 'Fantasy';

  @override
  Widget build(BuildContext context) {
    // Ephemeral project refreshed on every rebuild so the genre switch takes
    // effect immediately (ProjectBook.didUpdateWidget now reacts to genre).
    final mockProject = Project(
      title: 'The Prototype',
      createdAt: DateTime.now(),
      genre: _selectedGenre,
    );

    // Dynamic theme: every genre tints the scene with its ambient glow colour.
    final glow = GenreGlowRegistry.styleFor(_selectedGenre);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Book Widget Demo'),
        backgroundColor: const Color(0xFF121214),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121214),
      body: Stack(
        children: [
          // ── Screen-level ambient glow ──────────────────────────────────
          // Follows the selected genre like CSS `filter: blur()` on the glow
          // disc; ImageFiltered blurs the circle itself (BackdropFilter would
          // only blur what is painted *behind* it).
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ImageFiltered(
                  imageFilter: dart_ui.ImageFilter.blur(
                    sigmaX: 120,
                    sigmaY: 120,
                    tileMode: dart_ui.TileMode.decal,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    width: 600,
                    height: 600,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glow.particleColor.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Foreground content ─────────────────────────────────────────
          Column(
            children: [
              // Genre control pill (prototype `.controls`)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Genre:',
                        style: TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedGenre,
                        isExpanded: false,
                        dropdownColor: const Color(0xFF2a2a2a),
                        iconEnabledColor: Colors.white54,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        underline: const SizedBox.shrink(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedGenre = newValue);
                          }
                        },
                        items: _genreDropdownItems(),
                      ),
                    ],
                  ),
                ),
              ),

              // Book view (prototype `.scene` 300×420)
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 420,
                    child: ProjectBook(
                      project: mockProject,
                      destinationBuilder: (context) =>
                          _ProjectWorkspace(project: mockProject),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Port of the prototype's `#project-ui` overlay: a project workspace sidebar
/// with the AI Prompt Assistant plus the "Project Loaded Successfully" main
/// area that surfaces the streamed generation result.
///
/// Responsive: on narrow screens the sidebar becomes a [Drawer] so the layout
/// remains usable on phones; on wider windows it is a fixed left rail.
class _ProjectWorkspace extends StatefulWidget {
  const _ProjectWorkspace({required this.project});

  final Project project;

  @override
  State<_ProjectWorkspace> createState() => _ProjectWorkspaceState();
}

class _ProjectWorkspaceState extends State<_ProjectWorkspace> {
  static const String _defaultHint =
      'e.g., Write the introductory scene where our hero discovers a glowing '
      'relic...';

  /// Below this width the sidebar collapses into a [Drawer].
  static const double _narrowBreakpoint = 760;

  final TextEditingController _promptController = TextEditingController();
  String _promptHint = _defaultHint;

  /// Genre used by the assistant, independent from the cover genre so users
  /// can draft against any palette.
  late String _assistantGenre = widget.project.genre ?? 'Fantasy';

  bool _isGenerating = false;

  /// The streamed output. `null` = card hidden, `''` = card shown while the
  /// first characters are still on their way.
  String? _generatedText;
  Timer? _streamTimer;

  @override
  void dispose() {
    _streamTimer?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  /// Simulates a mock streaming AI response by revealing the generated text a
  /// few characters per tick, matching the "Generate Content" flow of the
  /// prototype while feeling like a live stream.
  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      // Prototype swaps the placeholder to prompt the user, then restores it.
      setState(() => _promptHint = 'Please enter a prompt first!');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _promptHint = _defaultHint);
      return;
    }

    final fullText = _buildGeneratedText(prompt, _assistantGenre);
    _streamTimer?.cancel();

    setState(() {
      _isGenerating = true;
      _generatedText = ''; // reveal the card immediately
    });

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    var charsRevealed = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      charsRevealed = math.min(charsRevealed + 3, fullText.length);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _generatedText = fullText.substring(0, charsRevealed));
      if (charsRevealed >= fullText.length) {
        timer.cancel();
        if (mounted) setState(() => _isGenerating = false);
      }
    });
  }

  /// Template story body interpolating the active genre, mirroring the
  /// prototype's simulated response.
  String _buildGeneratedText(String prompt, String genre) =>
      '[Generated for "$prompt"]\n\nThe mist clung tightly to the '
      'cobblestones of the ancient citadel. As the stars shifted alignment '
      'across the darkened canopy, an unfamiliar resonance pulsed from within '
      'the archives. It was precisely as the prophecies of the $genre '
      'chronicles had foretold—a dawn born from silence and unwavering '
      'resolve.';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < _narrowBreakpoint;
        if (isNarrow) {
          return Scaffold(
            backgroundColor: const Color(0xFF121214),
            appBar: AppBar(
              backgroundColor: const Color(0xFF141415),
              foregroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(LucideIcons.menu),
                  tooltip: 'Open menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: const Text(
                'Project Workspace',
                style: TextStyle(fontSize: 16),
              ),
            ),
            drawer: Drawer(
              backgroundColor: const Color(0xFF141415),
              width: 288, // prototype `w-72`
              child: _buildSidebar(),
            ),
            body: _buildMainArea(),
          );
        }

        // Wide layout: fixed left rail beside the content (prototype Row).
        return Scaffold(
          backgroundColor: const Color(0xFF121214),
          body: Row(
            children: [
              SizedBox(width: 288, child: _buildSidebar()),
              Expanded(child: _buildMainArea()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 288, // prototype `w-72`
      color: const Color(0xFF141415),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Project Workspace',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _SidebarLink(icon: LucideIcons.bookOpen, label: 'Master the Wiki'),
          const SizedBox(height: 8),
          _SidebarLink(icon: LucideIcons.clock, label: 'Make a Timeline'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1F2937), height: 1),
          const SizedBox(height: 16),

          // ── AI Prompt Assistant ────────────────────────────────────────
          const Row(
            children: [
              Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'AI Prompt Assistant',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Instruct the assistant to generate text or structure your book '
            'chapters based on your active genre.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: _promptHint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E20),
              isDense: true,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF59E0B)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Assistant genre picker
          Row(
            children: [
              const Icon(LucideIcons.tag, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              const Text(
                'Genre:',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _assistantGenre,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: const Color(0xFF2a2a2a),
                    iconEnabledColor: Colors.white54,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: _isGenerating
                        ? null
                        : (String? newValue) {
                            if (newValue != null) {
                              setState(() => _assistantGenre = newValue);
                            }
                          },
                    items: _genreDropdownItems(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: _isGenerating ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706), // amber-600
                disabledBackgroundColor: const Color(
                  0xFFD97706,
                ).withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.zap, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    _isGenerating ? 'Generating...' : 'Generate Content',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Close Project ──────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close Project',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    final generated = _generatedText;
    return Container(
      color: const Color(0xFF121214),
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Project Loaded Successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use the AI Prompt Assistant on the left sidebar to generate '
                'custom content instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Generated result card (prototype `#output-container`), shown
              // as soon as streaming begins and filled character by character.
              if (generated != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141415),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F2937)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Generated Result',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFFBBF24), // amber-400
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _assistantGenre,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF1F2937), height: 1),
                      const SizedBox(height: 16),

                      // Thin progress bar while the mock stream is running.
                      if (_isGenerating) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Color(0xFF1F2937),
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (generated.isEmpty)
                        const Text(
                          'Thinking',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          generated,
                          style: const TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  const _SidebarLink({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
