import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/create_project_dialog.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/dashboard_topbar.dart';
import 'widgets/action_card.dart';
import 'widgets/project_recent_grid.dart';
import 'widgets/project_list_table.dart';
import 'package:lore_keeper/screens/dashboard/project_browser_screen.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/models/project.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // hero height is 400. Topbar is 64.
    const double heroHeight = 400;
    const double topBarHeight = 64;

    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset > (heroHeight - topBarHeight)) {
        if (_opacity != 1.0) {
          setState(() => _opacity = 1.0);
        }
      } else {
        if (_opacity != 0.0) {
          setState(() => _opacity = 0.0);
        }
      }
    }
  }

  void _showCreateProjectDialog(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CreateProjectDialog();
      },
    ).then((result) {
      if (result == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    });
  }

  void _openProjectBrowser(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProjectBrowserScreen()));
  }

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectEditorScreen(project: project)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero
                const DashboardHero(),

                // Content with negative margin overlap simulation
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    children: [
                      // Search Bar Wrapper
                      const HeroSearchBar(),

                      const SizedBox(height: 64),

                      // Main Container
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Quick Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: ActionCard(
                                      icon: '✨',
                                      title: 'New Project',
                                      description:
                                          'Start a fresh manuscript with world-building templates.',
                                      onTap: () =>
                                          _showCreateProjectDialog(context),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: ActionCard(
                                      icon: '📚',
                                      title: 'Project Browser',
                                      description:
                                          'Explore and manage your library of created settings.',
                                      onTap: () => _openProjectBrowser(context),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: ActionCard(
                                      icon: '📥',
                                      title: 'Import',
                                      description:
                                          'Bring in files from Word, Scrivener, or plain text.',
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 64),

                              // Recent Manuscripts
                              _buildSectionHeader('🕑', 'Recent Manuscripts'),
                              ProjectRecentGrid(
                                onProjectTap: (project) =>
                                    _openProject(context, project),
                              ),

                              const SizedBox(height: 64),

                              // Project Global Repository
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildSectionHeader(
                                    '📚',
                                    'Project Repository',
                                  ),
                                ],
                              ),
                              const ProjectListTable(),

                              const SizedBox(height: 100), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Topbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _opacity,
              child: DashboardTopbar(opacity: _opacity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
