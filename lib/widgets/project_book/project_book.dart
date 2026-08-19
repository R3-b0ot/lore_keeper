// lib/widgets/project_book/project_book.dart
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'book_open_transition.dart';
import 'book_painters.dart';
import 'genre_glow.dart';
import 'project_book_view.dart';

BookViewInfo buildBookInfo(Project project) {
  final genre = project.genre ?? 'General';
  final hash = project.title.hashCode.abs();
  // `wordCount` stays empty on purpose: the cover never renders it, and
  // counting live words would synchronously scan every chapter of the whole
  // manuscript on the main thread for every grid rebuild (a measurable
  // multi-hundred-ms freeze with real projects).
  return BookViewInfo(
    title: project.title,
    genre: genre,
    wordCount: '',
    time: _formatDate(project.lastModified ?? project.createdAt),
    glow: GenreGlowRegistry.styleFor(project.genre),
    seed: (hash % 9999) / 9999,
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${date.month}/${date.day}/${date.year}';
}

class ProjectBook extends StatefulWidget {
  const ProjectBook({
    super.key,
    required this.project,
    this.onSettingsTap,
    this.onDeleteTap,
    this.onOpen,
    this.destinationBuilder,
    this.onHoverGlowChanged,
  });

  final Project project;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onOpen;
  final WidgetBuilder? destinationBuilder;

  /// Called with the genre glow colour when hovering starts, and [null] on exit.
  /// Consumers can use this to render a screen-level ambient glow behind the grid.
  final void Function(Color?)? onHoverGlowChanged;

  @override
  State<ProjectBook> createState() => _ProjectBookState();
}

class _ProjectBookState extends State<ProjectBook>
    with TickerProviderStateMixin {
  late final AnimationController _hoverController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  /// Prototype front-cover transition: `0.4s cubic-bezier(0.2, 0.8, 0.2, 1)`.
  /// Only the cover rotates on hover — the book body stays put.
  static const Cubic _hoverCurve = Cubic(0.2, 0.8, 0.2, 1.0);

  late final AnimationController _particleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  /// +38° swings the cover's free edge TOWARD the viewer (the depth-mirror of
  /// the prototype's CSS `rotateY(-38deg)`), so hover reads as the cover
  /// peeling open over the page — not a door or cabinet panel.
  static const double _hoverOpenAngle = 38.0 * math.pi / 180.0;
  late BookViewInfo _info;
  List<Particle> _particles = [];
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _info = buildBookInfo(widget.project);
    _particleController.addListener(() {
      if (_isHovering) {
        setState(() {
          for (final p in _particles) {
            p.update();
            if (p.life >= p.maxLife) {
              // Respawn at the prototype's emit column (rightEdgeX = centerX
              // + 60 → box-local x = 120 + 60 = 180).
              p.reset(180, 170);
            }
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProjectBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare by key and, for ephemeral (un-boxed) projects whose Hive key is
    // null, by genre/title so e.g. the demo's genre switch refreshes the cover.
    final keyChanged = oldWidget.project.key != widget.project.key;
    final metadataChanged =
        oldWidget.project.genre != widget.project.genre ||
        oldWidget.project.title != widget.project.title;
    if (keyChanged || metadataChanged) {
      _info = buildBookInfo(widget.project);
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onEnter() {
    widget.onHoverGlowChanged?.call(_info.glow.particleColor);
    setState(() {
      _isHovering = true;
      _particles = List.generate(40, (_) {
        final p = Particle();
        // 40 particles emitted from the prototype's column (box-local
        // x = centerX + 60 = 120 + 60 = 180), just inside the cover's right
        // edge — exactly like the HTML canvas.
        p.reset(180, 170);
        return p;
      });
    });
    _hoverController.forward();
    _particleController.repeat();
  }

  void _onExit() {
    widget.onHoverGlowChanged?.call(null);
    setState(() {
      _isHovering = false;
    });
    _hoverController.reverse();
    _particleController.stop();
  }

  /// Guards against double navigation while the book-open route runs. Reset
  /// when the pushed route completes (or immediately for consumer-handled
  /// opens), so the card becomes clickable again after navigating back.
  bool _isOpening = false;

  void _open() {
    if (_isOpening) return;
    _isOpening = true;

    // Preserve the hover-open position: the overlay resumes the cover swing
    // from the exact angle reached at the moment of the click (it never snaps
    // back to closed).
    final initialOpenAngle =
        _hoverCurve.transform(_hoverController.value) * _hoverOpenAngle;

    // Clicking immediately stops the hover particles and ambient glow, and
    // lets the card's own cover settle while the route's overlay takes over.
    _onExit();

    if (widget.onOpen != null) {
      widget.onOpen!();
      _isOpening = false;
      return;
    }

    final rect = _globalRect();
    if (rect.isEmpty) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: _destination));
      _isOpening = false;
      return;
    }

    Navigator.of(context)
        .push(
          buildBookOpenRoute(
            project: widget.project,
            info: _info,
            originRect: rect,
            initialOpenAngle: initialOpenAngle,
            destinationBuilder: _destination,
          ),
        )
        .whenComplete(() => _isOpening = false);
  }

  Widget _destination(BuildContext context) {
    final builder = widget.destinationBuilder;
    return builder?.call(context) ??
        ProjectEditorScreen(project: widget.project);
  }

  Rect _globalRect() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return Rect.zero;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _hoverController,
              builder: (context, _) {
                final hover = _hoverController.value;
                // Prototype cover transition: cubic-bezier(0.2, 0.8, 0.2, 1).
                // Only the cover rotates — the wrapper/book body does not move.
                final lift = _hoverCurve.transform(hover);
                final openAngle = lift * _hoverOpenAngle;
                final hasActions =
                    widget.onSettingsTap != null || widget.onDeleteTap != null;

                // Scale 240x340 into the available space
                return FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 240,
                    height: 340,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ambient glow — ImageFiltered blurs the widget itself,
                        // matching CSS #ambient-glow: 500x500, `blur(90px)`,
                        // `rgba(color, 0.22)`, `opacity 0.4s`.
                        Positioned(
                          top: -80, // 170 - 250 (centred on the book)
                          left: -130, // 120 - 250
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: _isHovering ? 1.0 : 0.0,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 90,
                                  sigmaY: 90,
                                  tileMode: TileMode.decal,
                                ),
                                child: Container(
                                  width: 500,
                                  height: 500,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _info.glow.particleColor.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3D perspective scene
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, bookPerspectiveFactor),
                          child: ProjectBookView(
                            info: _info,
                            openAngle: openAngle,
                          ),
                        ),

                        // Particle Canvas — always mounted, opacity faded in
                        // like the CSS `#particle-canvas { transition: 0.2s }`.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isHovering ? 1.0 : 0.0,
                              child: CustomPaint(
                                painter: ParticlePainter(
                                  particles: _particles,
                                  style: _info.glow,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Actions
                        if (hasActions)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Opacity(
                              opacity: 0.5 + 0.5 * hover,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ActionButton(
                                    icon: LucideIcons.settings,
                                    tooltip: 'Settings',
                                    onTap: widget.onSettingsTap,
                                  ),
                                  const SizedBox(width: 6),
                                  _ActionButton(
                                    icon: LucideIcons.trash2,
                                    tooltip: 'Delete',
                                    onTap: widget.onDeleteTap,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(
            icon,
            size: 15,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
