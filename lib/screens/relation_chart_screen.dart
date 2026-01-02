// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
// =================================================================
// 1. SCREEN AND STATE MANAGEMENT
// =================================================================

class RelationChartScreen extends StatefulWidget {
  final dynamic startCharacterKey;
  final List<dynamic> history;
  final int iterationIndex;
  const RelationChartScreen({
    super.key,
    required this.startCharacterKey,
    this.history = const [],
    this.iterationIndex = 0,
  });

  @override
  State<RelationChartScreen> createState() => _RelationChartScreenState();
}

class _RelationChartScreenState extends State<RelationChartScreen>
    with SingleTickerProviderStateMixin {
  final double nodeDim = 180.0;
  final double buttonDim = 50.0;

  // --- Performance Optimization: State variables ---
  // Store computed values to avoid recalculating in build().
  Character? _centerNode;
  // A list of tuples, where each entry represents a unique node on the chart.
  // This allows the same character to appear multiple times for different links.
  List<(Link, Character)> _externalNodes = [];
  List<Link> _connectedLinks = [];
  Map<dynamic, Offset> _nodePositions = {};
  Size _canvasSize = Size.zero;
  // --- End Optimization ---

  final TransformationController _transformationController =
      TransformationController();

  // Use a ValueNotifier for scale to avoid rebuilding the entire screen on zoom.
  final ValueNotifier<double> _scaleNotifier = ValueNotifier(1.0);

  late Box<Character> _characterBox;
  late Box<Link> _linkBox;

  // --- Animation for Smooth Zooming ---
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  // --- End Animation ---

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for smooth zooming
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Listener to update the Slider value when InteractiveViewer is manually zoomed
    _transformationController.addListener(_onTransformationUpdate);
    _loadData();
  }

  void _onTransformationUpdate() {
    // The scale factor is typically stored at index 0 of the Matrix4's storage array
    final matrixScale = _transformationController.value.storage[0];
    if (_scaleNotifier.value != matrixScale) {
      _scaleNotifier.value = matrixScale;
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationUpdate);
    _transformationController.dispose();
    _animationController.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _characterBox = Hive.box<Character>('characters');
    _linkBox = Hive.box<Link>('links');

    final centerNode = _characterBox.get(widget.startCharacterKey);
    if (centerNode == null) {
      if (mounted) setState(() {}); // Trigger a build to show an empty state
      return;
    }

    // --- Performance Optimization: Efficiently filter links ---
    // Iterate over keys, not values, to avoid loading all links into memory.
    final List<Link> connectedLinks = [];
    for (final key in _linkBox.keys) {
      final link = _linkBox.get(key);
      if (link != null &&
          ((link.entity1Key == centerNode.key &&
                  link.entity1IterationIndex == widget.iterationIndex) ||
              (link.entity2Key == centerNode.key &&
                  link.entity2IterationIndex == widget.iterationIndex))) {
        connectedLinks.add(link);
      }
    }

    final List<(Link, Character)> externalNodes = [];
    for (final link in connectedLinks) {
      final otherKey = link.entity1Key == centerNode.key
          ? link.entity2Key
          : link.entity1Key;
      final otherChar = _characterBox.get(otherKey);
      if (otherChar != null) {
        externalNodes.add((link, otherChar));
      }
    }

    setState(() {
      // --- FIX: Load layout *before* checking if it's empty ---
      _centerNode = centerNode;
      _connectedLinks = connectedLinks;
      _externalNodes = externalNodes;

      _nodePositions =
          centerNode.relationWebLayout?.map(
            (key, value) => MapEntry(key, Offset(value['dx']!, value['dy']!)),
          ) ??
          {};
      // --- END FIX ---
    });

    // Auto-layout on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // --- FIX: Update state after calculating canvas size ---
      setState(() {
        final screenSize = MediaQuery.of(context).size;
        _canvasSize = Size(screenSize.width * 5, screenSize.height * 5);
        if (_nodePositions.isEmpty) _autoLayout();
        _resetAndCenterView();
      });
      // --- END FIX ---
    });
  }

  // NEW: Saves the current node positions to the central character's record.
  Future<void> _saveLayout() async {
    final centerNode = _centerNode;
    if (centerNode == null) return;

    // Convert Offset objects to a Hive-compatible format.
    final savableLayout = _nodePositions.map(
      (key, value) => MapEntry(key, {'dx': value.dx, 'dy': value.dy}),
    );
    centerNode.relationWebLayout =
        savableLayout; // This still saves by character key, which is what we want for persistence.
    await centerNode.save();
  }

  // --- NEW: Animate to a target matrix for smooth transitions ---
  void _animateToMatrix(Matrix4 targetMatrix) {
    _animationController.stop();

    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animation!.addListener(() {
      if (mounted) {
        _transformationController.value = _animation!.value;
      }
    });

    _animationController.forward(from: 0.0);
  }

  // NEW: Generates the hook points on the web.
  Map<String, List<Offset>> _generateWebHookPoints(
    Size canvasSize, {
    required int numberOfRings,
  }) {
    final Map<String, List<Offset>> hookPointsByDirection = {};
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    // Dynamically generate the radii for the concentric rings
    final List<double> ringRadii = [];
    if (numberOfRings > 0) {
      // Radius for the first ring
      final double firstRingRadius =
          (nodeDim / 2) + // Half of central node.
          (nodeDim *
              0.20) + // Gap from central node to button. // This was correct
          buttonDim + // Button size.
          (nodeDim +
              (buttonDim *
                  0.20)) + // Gap from button to node (100% node + 20% button).
          (nodeDim / 2); // Half of external node.
      ringRadii.add(firstRingRadius);

      // Spacing for subsequent rings
      final double spacing = nodeDim + (buttonDim * 0.20);
      for (int i = 1; i < numberOfRings; i++) {
        ringRadii.add(ringRadii.last + spacing);
      }
    }

    const Map<String, double> directionToAngle = {
      'top': 270,
      'bottom': 90,
      'left': 180,
      'right': 0,
      'top-left': 225,
      'top-right': 315,
      'bottom-left': 135,
      'bottom-right': 45,
    };

    directionToAngle.forEach((direction, angle) {
      final angleRadians = angle * (pi / 180);
      final pointsOnRadial = <Offset>[];

      for (final radius in ringRadii) {
        final x = centerX + radius * cos(angleRadians);
        final y = centerY + radius * sin(angleRadians);
        // Store the top-left position for the node
        pointsOnRadial.add(Offset(x - nodeDim / 2, y - nodeDim / 2));
      }
      hookPointsByDirection[direction] = pointsOnRadial;
    });

    return hookPointsByDirection;
  }

  // Determines the relationship description based on the current character
  String _getRelationDescription(Link link, dynamic centerKey) {
    if (link.entity1Key == centerKey) {
      return link.description;
    } else if (link.entity2Key == centerKey) {
      // The center character is entity2, so get the inverse from the service.
      switch (link.description) {
        case 'Parent':
          return 'Child';
        case 'Child':
          return 'Parent';
        case 'Mentor':
          return 'Mentee';
        case 'Mentee':
          return 'Mentor';
        // Symmetric relationships return themselves.
        case 'Spouse':
        case 'Sibling':
        case 'Friend':
        case 'Rival':
          return link.description;
        // Default case for any other relationship types.
        default:
          return link.description;
      }
    } else {
      // Fallback if the link doesn't involve the center (should not happen in this context)
      return link.description;
    }
  }

  // Calculates the position of the relation buttons relative to the center node
  Offset _getButtonPosition(String direction) {
    const double nodeHalf = 180 / 2;
    const double buttonHalf = 50.0 / 2; // buttonDim / 2
    // The gap between the node edge and button edge is 20% of the node's dimension.
    const double separation = 180.0 * 0.20; // 36.0

    switch (direction) {
      case 'top':
        return Offset(nodeHalf - buttonHalf, -buttonDim - separation);
      case 'bottom':
        // Corrected calculation for bottom offset: need to account for nodeDim
        return Offset(nodeHalf - buttonHalf, nodeDim + separation);
      case 'left':
        return Offset(-buttonDim - separation, nodeHalf - buttonHalf);
      case 'right':
        // Corrected calculation for right offset: need to account for nodeDim
        return Offset(nodeDim + separation, nodeHalf - buttonHalf);
      case 'top-left':
        return Offset(-buttonDim - separation, -buttonDim - separation);
      case 'top-right':
        // Corrected calculation for top-right x offset
        return Offset(nodeDim + separation, -buttonDim - separation);
      case 'bottom-left':
        // Corrected calculation for bottom-left y offset
        return Offset(-buttonDim - separation, nodeDim + separation);
      case 'bottom-right':
        return Offset(nodeDim + separation, nodeDim + separation);
      default:
        return Offset.zero;
    }
  }

  // Opens a dialog to select a new character to add
  void _showAddRelationModal(
    String relationType,
    String direction,
    Offset buttonPosition,
  ) async {
    showDialog(
      context: context,
      builder: (context) => _AddRelationDialog(
        relationType: relationType,
        onCharacterSelected: (char, iterationIndex) {
          _addNode(char, relationType, direction, iterationIndex);
        },
        sourceCharacterKey: _centerNode?.key,
      ),
    );
  }

  // Adds a new character and relation
  void _addNode(
    Character char,
    String relationType,
    String direction,
    int? iterationIndex,
  ) {
    final newLink = Link()
      ..entity1Key = _centerNode!.key
      ..entity1Type = 'Character'
      ..entity2Key = char.key
      ..entity2Type = 'Character'
      ..description = relationType
      ..entity1IterationIndex = widget
          .iterationIndex // Use the current character's iteration index
      ..entity2IterationIndex = iterationIndex;

    _linkBox.add(newLink);

    setState(() {
      _externalNodes.add((newLink, char));
      _connectedLinks.add(newLink);
      // Auto-layout after adding a new character
      _autoLayout();
    });
  }

  void _deleteNode(Link linkToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Node'),
        content: Text(
          // FIX: Use link description in dialog
          'Are you sure you want to delete the node for "${linkToDelete.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _linkBox.delete(linkToDelete.key);

    setState(() {
      _externalNodes.removeWhere((node) => node.$1.key == linkToDelete.key);
      _connectedLinks.remove(linkToDelete);
      _nodePositions.remove(linkToDelete.key);
    });
  }

  void _deleteAllNodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Links'),
        content: const Text(
          'Are you sure you want to delete all nodes linked to the current character? (This will remove the links, not the characters themselves)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Delete all links from the database
    for (final link in _connectedLinks) {
      await _linkBox.delete(link.key);
    }

    // Reset state
    setState(() {
      _externalNodes.clear();
      _connectedLinks.clear();
      _nodePositions.clear();
    });
  }

  // Auto-sorts the external nodes to their calculated directional positions
  void _autoLayout() {
    final centerKey = _centerNode?.key;
    if (centerKey == null) return;

    final directionToLinks = <String, List<Link>>{};
    // Correctly handle bidirectional relationships
    for (final rel in _connectedLinks) {
      if (rel.entity1Key == centerKey) {
        // continue
      } else if (rel.entity2Key == centerKey) {
        // continue
      } else {
        continue; // This relation doesn't involve the center node
      }

      // Use the corrected relation description to find the direction
      final direction = _getDirectionForRelation(
        _getRelationDescription(rel, centerKey),
      );

      (directionToLinks[direction] ??= []).add(rel);
    }

    // Determine the maximum number of rings needed for the web
    int maxRelationsInOneDirection = 0;
    directionToLinks.forEach((_, links) {
      if (links.length > maxRelationsInOneDirection) {
        maxRelationsInOneDirection = links.length;
      }
    });

    // Generate the hook points on the web
    final hookPoints = _generateWebHookPoints(
      _canvasSize,
      numberOfRings: maxRelationsInOneDirection,
    );
    final newPositions = Map<dynamic, Offset>.from(_nodePositions);

    directionToLinks.forEach((direction, links) {
      final pointsForDirection = hookPoints[direction] ?? [];
      for (int i = 0; i < links.length; i++) {
        if (i >= pointsForDirection.length) break; // Safety check

        final link = links[i];
        newPositions[link.key] = pointsForDirection[i];
      }
    });

    setState(() {
      _nodePositions = newPositions;
      _saveLayout(); // Save the new layout after auto-sorting
    });
  }

  String _getDirectionForRelation(String relationType) {
    const Map<String, String> relationToDirection = {
      'Parent': 'top',
      'Rival': 'top-left',
      'Sibling': 'top-right',
      'Friend': 'left',
      'Spouse': 'right',
      'Mentor': 'bottom-left',
      'Child': 'bottom',
      'Mentee': 'bottom-right',
    };
    return relationToDirection[relationType] ?? 'bottom';
  }

  void _resetAndCenterView() {
    // Calculate the translation needed to move the center node's center (canvasCenter)
    // to the InteractiveViewer's center. The InteractiveViewer's center is (0,0) in world space
    // when unscaled and untranslated. The target center of the node is (canvasSize.width / 2, canvasSize.height / 2).

    // We want the current view center (0,0 in screen space) to look at the node center.
    // The required matrix is simply the inverse of the node's position.
    final double targetX = _canvasSize.width / 2;
    final double targetY = _canvasSize.height / 2;

    // Matrix to translate the view to put (targetX, targetY) at the screen's center
    final matrix = Matrix4.translationValues(
      -targetX + MediaQuery.of(context).size.width / 2,
      -targetY + MediaQuery.of(context).size.height / 2,
      0.0,
    )..scale(Vector3(1.0, 1.0, 1.0));

    _animateToMatrix(matrix);
  }

  // NEW: Snap-to-grid logic on drag end
  void _onNodeDragEnd(DragEndDetails details, Link link) {
    final currentPos = _nodePositions[link.key] ?? Offset.zero;

    // Generate all possible hook points
    final allHookPoints = _generateWebHookPoints(
      _canvasSize,
      // Generate enough rings to accommodate all current nodes, plus a few extra for snapping.
      // This ensures that if the user drags a node, there are empty spots to snap to.
      numberOfRings: _externalNodes.length + 3,
    ).values.expand((points) => points).toList();

    // Find the hook points that are not currently occupied
    final occupiedPositions = _nodePositions.values.toSet();
    final availableHookPoints = allHookPoints
        .where((p) => !occupiedPositions.contains(p))
        .toList();

    if (availableHookPoints.isEmpty) return; // No free spots to snap to

    // Find the closest available hook point
    Offset closestPoint = availableHookPoints.first;
    double minDistance = (currentPos - closestPoint).distanceSquared;

    for (final point in availableHookPoints.skip(1)) {
      final distance = (currentPos - point).distanceSquared;
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    // Here you would update the link's direction if the snap changes its category
    // For now, we just snap the position.

    setState(() {
      _nodePositions[link.key] = closestPoint;
      _saveLayout(); // Save layout after snapping
    });
  }

  // =================================================================
  // 5. UI BUILDING WIDGETS
  // =================================================================
  // Builds the single character node widget (used for all nodes)
  Widget _buildNode(Character char, bool isCenter) {
    final color = isCenter
        ? Theme.of(context)
              .colorScheme
              .primary // Correctly set to purple
        : Colors.blueGrey;

    String iterationTitle = 'No Iteration';
    if (isCenter) {
      if (char.iterations.length > widget.iterationIndex) {
        iterationTitle = char.iterations[widget.iterationIndex].iterationName;
      }
    } else {
      // Find the link connecting this external character to the center node
      final relevantLink = _externalNodes.firstWhere(
        (node) =>
            (node.$1.entity1Key == _centerNode?.key &&
                node.$1.entity2Key == char.key) ||
            (node.$1.entity2Key == _centerNode?.key &&
                node.$1.entity1Key == char.key),
        orElse: () => (Link(), Character(name: '', parentProjectId: -1)),
      );

      if (relevantLink.$1.key != null) {
        // Check if a link was found
        // Check if a link was found
        final int? externalIterationIndex =
            relevantLink.$1.entity1Key == char.key
            ? relevantLink.$1.entity1IterationIndex
            : relevantLink.$1.entity2IterationIndex;

        if (externalIterationIndex != null &&
            char.iterations.length > externalIterationIndex) {
          iterationTitle =
              char.iterations[externalIterationIndex].iterationName;
        }
      }
    }

    final nodeWidget = GestureDetector(
      // Drag handlers are now on _buildDraggableNode
      onTap: () {
        if (!isCenter) {
          // Add the current character to the history and navigate to the new chart.
          final newHistory = List<dynamic>.from(widget.history)
            ..add(widget.startCharacterKey);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RelationChartScreen(
                startCharacterKey: char.key,
                iterationIndex: 0, // Default to first iteration for now
                history: newHistory,
              ),
            ),
          );
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: nodeDim,
          maxWidth: nodeDim,
          minHeight: nodeDim,
          maxHeight: nodeDim,
        ),
        child: Container(
          width: nodeDim,
          height: nodeDim,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: color, width: isCenter ? 3.0 : 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content with 50/50 split
              Column(
                children: [
                  // Top 50% for Portrait
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: color.withAlpha((255 * 0.2).round()),
                        child: Text(
                          char.name.substring(0, 1),
                          style: TextStyle(
                            fontSize: 32,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom 50% for Text
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            char.name, // This was correct
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            iterationTitle,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Kebab menu in the top-right corner
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      // The logic for deleting is now in _buildNodeContent,
                      // which receives the link for external nodes.
                      // This PopupMenuButton is part of the old _buildNode logic
                      // and is effectively unused now. The real one is in _buildNodeContent.
                      // We can leave this as is or remove it, but it's not hurting anything.
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        isCenter ? 'Delete All Links' : 'Delete Link',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isCenter) {
      return nodeWidget;
    }

    return Positioned(
      left: 0.0, // This will be handled by the new build logic
      top: 0.0, // This will be handled by the new build logic
      child: nodeWidget,
    );
  }

  // Builds the central node and its eight relation buttons
  Widget _buildCentralGroup(Offset centerGroupOffset) {
    final centerNode = _centerNode;
    if (centerNode == null) {
      return const SizedBox.shrink();
    }
    // Map of direction to relation type and button color
    const Map<String, dynamic> relationsMap = {
      'top': {
        // This was correct
        'type': 'Parent',
        'color': Colors.purple,
        'icon': Icons.arrow_upward, // Kept for directional clarity
      },
      'top-left': {
        'type': 'Rival',
        'color': Colors.red,
        'icon': Icons.bolt, // Thematic icon for Rival
      },
      'top-right': {
        'type': 'Sibling',
        'color': Colors.amber,
        'icon': Icons.groups, // Thematic icon for Sibling
      },
      'left': {
        'type': 'Friend',
        'color': Colors.teal,
        'icon': Icons.handshake, // Thematic icon for Friend
      },
      'right': {
        'type': 'Spouse',
        'color': Colors.pink,
        'icon': Icons.favorite, // Thematic icon for Spouse
      },
      'bottom-left': {
        'type': 'Mentor',
        'color': Colors.blue,
        'icon': Icons.school, // This is a good thematic icon
      },
      'bottom': {
        'type': 'Child',
        'color': Colors.indigo,
        'icon': Icons.arrow_downward, // Kept for directional clarity
      },
      'bottom-right': {
        'type': 'Mentee',
        'color': Colors.orange,
        'icon': Icons.face, // Thematic icon for Mentee
      },
    };

    // Define the total size of the central group including buttons
    final double groupWidth =
        nodeDim + (buttonDim * 2) + ((nodeDim * 0.20) * 2);
    final double groupHeight =
        nodeDim + (buttonDim * 2) + ((nodeDim * 0.20) * 2);

    // Calculate the offset needed to shift the entire group up and left
    // to account for the buttons in the negative space.
    final double xOffset = buttonDim + (nodeDim * 0.20);
    final double yOffset = buttonDim + (nodeDim * 0.20);

    return Positioned(
      left: centerGroupOffset.dx - xOffset,
      top: centerGroupOffset.dy - yOffset,
      child: SizedBox(
        width: groupWidth,
        height: groupHeight,
        child: Stack(
          // Use a Stack that is large enough to contain the node and its buttons
          clipBehavior: Clip.none,
          children: [
            // The central node needs to be positioned within the new, larger SizedBox
            Positioned(
              left: xOffset,
              top: yOffset,
              child: _buildNode(centerNode, true),
            ),
            // Position buttons around the central node
            ...relationsMap.entries.map((entry) {
              final direction = entry.key;
              final relationType = entry.value['type'] as String;
              final color = entry.value['color'] as Color;
              final icon = entry.value['icon'] as IconData;
              final buttonPosition = _getButtonPosition(direction);
              return Positioned(
                left: buttonPosition.dx + xOffset,
                top: buttonPosition.dy + yOffset,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Tooltip(
                    message: 'Add $relationType',
                    child: FloatingActionButton(
                      heroTag: relationType, // Must be unique
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _showAddRelationModal(
                          // This is correct
                          relationType,
                          direction,
                          buttonPosition,
                        );
                      },
                      child: Icon(icon, size: 24),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centerChar = _centerNode;

    if (_canvasSize == Size.zero || centerChar == null) {
      // Data is not loaded yet, show a loading indicator or an empty app bar.
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate the position for the central group (centered on canvas)
    final double centerGroupX = _canvasSize.width / 2 - nodeDim / 2;
    final double centerGroupY = _canvasSize.height / 2 - nodeDim / 2;
    final centerGroupOffset = Offset(centerGroupX, centerGroupY);

    return Scaffold(
      appBar: AppBar(
        // This was correct
        leadingWidth: 112, // Increase width to accommodate two buttons
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
            // Only show the back button if there is history
            if (widget.history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final previousKey = widget.history.last;
                  final newHistory = List<dynamic>.from(widget.history)
                    ..removeLast();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RelationChartScreen(
                        startCharacterKey: previousKey,
                        history: newHistory,
                      ),
                    ),
                  );
                },
                tooltip: 'Back to Previous Character',
              ),
          ],
        ),
        title: Text(centerChar.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Arrange nodes in their default positions',
              child: ElevatedButton.icon(
                onPressed: _autoLayout,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-Sort Layout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false, // Allow panning beyond the boundaries
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 2.5,
        child: SizedBox(
          // Define a large canvas for the chart to live on
          width: _canvasSize.width,
          height: _canvasSize.height,
          // --- Performance Optimization: RepaintBoundary ---
          // This prevents the complex stack of painters and nodes from redrawing
          // when the parent Scaffold or other UI elements change.
          child: RepaintBoundary(
            child: Stack(
              children: [
                // NEW: Draw the background web
                Positioned.fill(
                  child: CustomPaint(
                    painter: WebPainter(
                      center: Offset(
                        _canvasSize.width / 2,
                        _canvasSize.height / 2,
                      ),
                      // Generate radii based on the current layout needs
                      radii:
                          _generateWebHookPoints(
                                _canvasSize,
                                numberOfRings: _externalNodes.length + 1,
                              ).values.first
                              .map(
                                (p) =>
                                    (p -
                                            Offset(
                                              _canvasSize.width / 2 -
                                                  nodeDim / 2,
                                              _canvasSize.height / 2 -
                                                  nodeDim / 2,
                                            ))
                                        .distance,
                              )
                              .toList(),
                    ),
                  ),
                ),
                // 1. CustomPainter for Lines (Canvas)
                Positioned.fill(
                  child: CustomPaint(
                    painter: RelationPainter(
                      center: centerChar,
                      external: _externalNodes.map((e) => e.$2).toList(),
                      relations: _connectedLinks,
                      nodePositions: _nodePositions,
                      nodeDim: nodeDim,
                      // Pass the center point of the central node on the canvas
                      canvasCenter: Offset(
                        _canvasSize.width / 2,
                        _canvasSize.height / 2,
                      ),
                      getRelationDescription: _getRelationDescription,
                    ),
                  ),
                ),
                // 2. Central Group (Main Node and Buttons)
                _buildCentralGroup(centerGroupOffset),

                // 3. External Character Nodes
                ..._externalNodes.map(
                  (node) => _nodePositions.containsKey(node.$1.key)
                      ? _buildDraggableNode(node.$1, node.$2)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableNode(Link link, Character char) {
    final nodeWidget = GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final currentPos = _nodePositions[link.key] ?? Offset.zero;
          _nodePositions[link.key] = currentPos + details.delta;
        });
      },
      onPanEnd: (details) => _onNodeDragEnd(details, link),
      onTap: () {
        // Add the current character to the history and navigate to the new chart.
        final newHistory = List<dynamic>.from(widget.history)
          ..add(widget.startCharacterKey);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RelationChartScreen(
              startCharacterKey: char.key,
              iterationIndex:
                  0, // Default to first iteration when clicking through
              history: newHistory,
            ),
          ),
        );
      },
      child: _buildNodeContent(
        char,
        link,
      ), // A new method to build just the content
    );

    return Positioned(
      left: _nodePositions[link.key]?.dx ?? 0.0,
      top: _nodePositions[link.key]?.dy ?? 0.0,
      child: nodeWidget,
    );
  }

  Widget _buildNodeContent(Character char, Link? link) {
    final isCenter = link == null;
    final color = isCenter
        ? Theme.of(context).colorScheme.primary
        : Colors.blueGrey;

    // ... (rest of the _buildNode logic, but now it's just for content)
    // This is a simplified version of the logic from the old _buildNode
    // The full logic from _buildNode should be moved here.
    // For brevity, I'll show the key parts.

    String iterationTitle = 'No Iteration';
    if (isCenter) {
      if (char.iterations.length > widget.iterationIndex) {
        iterationTitle = char.iterations[widget.iterationIndex].iterationName;
      }
    } else {
      final int? externalIterationIndex = link.entity1Key == char.key
          ? link.entity1IterationIndex
          : link.entity2IterationIndex;

      if (externalIterationIndex != null &&
          char.iterations.length > externalIterationIndex) {
        iterationTitle = char.iterations[externalIterationIndex].iterationName;
      }
    }

    return Container(
      width: nodeDim,
      height: nodeDim,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: isCenter ? 3.0 : 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content with 50/50 split
          Column(
            children: [
              // Top 50% for Portrait
              Expanded(
                flex: 1,
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withAlpha((255 * 0.2).round()),
                    child: Text(
                      char.name.substring(0, 1),
                      style: TextStyle(
                        fontSize: 32,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom 50% for Text
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      char.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      iterationTitle,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Kebab menu in the top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  if (isCenter) {
                    _deleteAllNodes();
                  } else {
                    _deleteNode(link);
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    isCenter ? 'Delete All Links' : 'Delete Link',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Legend on the left
            Expanded(child: _buildLegend()),
            const VerticalDivider(),
            // Zoom controls on the right
            const Text('Zoom:'),
            SizedBox(
              width: 200,
              // Use a ValueListenableBuilder to only rebuild the slider when the scale changes.
              child: ValueListenableBuilder<double>(
                valueListenable: _scaleNotifier,
                builder: (context, scale, child) {
                  return Slider(
                    value: scale.clamp(0.1, 2.5),
                    min: 0.1,
                    max: 2.5,
                    onChanged: (newScale) {
                      // Directly update the matrix during active sliding for responsiveness.
                      // The animation is used for the final position in onChangeEnd.
                      _animationController.stop();

                      // --- FIX: Corrected zoom-to-center logic ---
                      // This ensures the slider zoom behaves identically to scroll-wheel zoom.
                      final currentMatrix = _transformationController.value;
                      final currentScale = currentMatrix.storage[0];

                      // If the scale is not changing, do nothing.
                      if (newScale == currentScale) return;

                      // 1. Get the center of the viewport in screen coordinates.
                      final viewportSize = MediaQuery.of(context).size;
                      final viewportCenter = Offset(
                        viewportSize.width / 2,
                        viewportSize.height / 2,
                      );

                      // 2. Find the point on the canvas that is currently under the viewport center.
                      final focalPoint = MatrixUtils.transformPoint(
                        currentMatrix.clone()..invert(),
                        viewportCenter,
                      );

                      // 3. Calculate the translation adjustment needed to keep the focal point centered after scaling.
                      final dx = (viewportCenter.dx - focalPoint.dx * newScale);
                      final dy = (viewportCenter.dy - focalPoint.dy * newScale);

                      // 4. Create and set the new matrix directly.
                      final newMatrix = Matrix4(
                        newScale,
                        0,
                        0,
                        0,
                        0,
                        newScale,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                        dx,
                        dy,
                        0,
                        1,
                      );
                      _transformationController.value = newMatrix;
                      // --- END FIX ---
                    },
                    onChangeEnd: (newScale) {
                      // --- NEW: Animate to the final position on slider release ---
                      // This provides a smooth final adjustment if needed, though direct
                      // manipulation during `onChanged` is often sufficient.
                      // The main benefit is consistency with other animated actions.
                      final finalMatrix = _transformationController.value;
                      _animateToMatrix(finalMatrix);
                      // --- END FIX ---
                    },
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Center View (Reset Position and Zoom)',
              onPressed: _resetAndCenterView,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const Map<String, dynamic> relationsMap = {
      'Parent': {'color': Colors.purple},
      'Rival': {'color': Colors.red},
      'Sibling': {'color': Colors.amber},
      'Friend': {'color': Colors.teal},
      'Spouse': {'color': Colors.pink},
      'Mentor': {'color': Colors.blue},
      'Child': {'color': Colors.indigo},
      'Mentee': {'color': Colors.orange},
    };
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: relationsMap.entries.map((entry) {
          return _LegendItem(
            color: entry.value['color'] as Color,
            label: entry.key,
          );
        }).toList(),
      ),
    );
  }
}

class _AddRelationDialog extends StatefulWidget {
  final String relationType;
  final Function(Character, int?) onCharacterSelected;
  final dynamic sourceCharacterKey;

  const _AddRelationDialog({
    required this.relationType,
    required this.onCharacterSelected,
    this.sourceCharacterKey,
  });

  @override
  State<_AddRelationDialog> createState() => _AddRelationDialogState();
}

class _AddRelationDialogState extends State<_AddRelationDialog> {
  String _view = 'character'; // 'character' or 'iteration'
  Character? _selectedCharacter;
  late Box<Character> _characterBox;

  @override
  void initState() {
    super.initState();
    _characterBox = Hive.box<Character>('characters');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _view == 'character'
            ? 'Add ${widget.relationType} Relation'
            : 'Select Iteration for ${_selectedCharacter?.name}',
      ),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_view == 'character') {
      final selectableChars = _characterBox.values
          .where((char) => char.key != widget.sourceCharacterKey)
          .toList();

      if (selectableChars.isEmpty) {
        return const Text('No other characters available to add.');
      }

      return ListView.builder(
        shrinkWrap: true,
        itemCount: selectableChars.length,
        itemBuilder: (context, index) {
          final char = selectableChars[index];
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(char.name)),
                if (char.iterations.length > 1)
                  const Icon(Icons.layers, size: 16, color: Colors.grey),
              ],
            ),
            subtitle: Text(char.iterations.first.occupation ?? 'No occupation'),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                char.name.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onTap: () {
              if (char.iterations.length > 1) {
                setState(() {
                  _selectedCharacter = char;
                  _view = 'iteration';
                });
              } else {
                widget.onCharacterSelected(char, 0);
                Navigator.of(context).pop();
              }
            },
          );
        },
      );
    } else {
      // Iteration view
      final iterations = _selectedCharacter?.iterations ?? [];
      if (iterations.isEmpty) {
        // This case should ideally not be hit if the logic is correct
        return const Center(child: Text('No iterations found.'));
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Back to Character List'),
            onTap: () {
              setState(() {
                _view = 'character';
                _selectedCharacter = null;
              });
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: iterations.length,
              itemBuilder: (context, index) {
                final iteration = iterations[index];
                return ListTile(
                  title: Text(iteration.iterationName),
                  subtitle: Text(iteration.name ?? ''),
                  onTap: () {
                    widget.onCharacterSelected(_selectedCharacter!, index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }
}

// =================================================================
// 6. CUSTOM PAINTER FOR LINES
// =================================================================

class RelationPainter extends CustomPainter {
  final Character center;
  final List<Character> external;
  final List<Link> relations;
  final Map<dynamic, Offset> nodePositions;
  final Offset canvasCenter;
  final double nodeDim;
  final String Function(Link, dynamic) getRelationDescription;

  RelationPainter({
    required this.center,
    required this.external,
    required this.relations,
    required this.canvasCenter,
    required this.nodePositions,
    required this.nodeDim,
    required this.getRelationDescription,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The center of the central node
    final centerPoint = canvasCenter;

    for (var rel in relations) {
      // Get the key of the other character
      // Skip if the target position hasn't been calculated yet
      if (!nodePositions.containsKey(rel.key)) continue;

      // Calculate the center point of the external node on the canvas
      final targetCenter = Offset(
        (nodePositions[rel.key]?.dx ?? 0) + nodeDim / 2,
        (nodePositions[rel.key]?.dy ?? 0) + nodeDim / 2,
      );

      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Determine line style based on relation type and color
      Color lineColor;
      IconData? iconData;
      const double strokeWidth = 2.0; // Set a uniform thickness for all lines

      switch (getRelationDescription(rel, center.key)) {
        case 'Spouse':
          iconData = Icons.favorite_border_rounded;
          lineColor = Colors.pink.shade700;
          break;
        case 'Friend':
          iconData = Icons.handshake_rounded;
          lineColor = Colors.teal.shade500;
          break;
        case 'Sibling':
          iconData = Icons.groups_rounded;
          lineColor = Colors.amber.shade600;
          break;
        case 'Parent':
          iconData = Icons.arrow_upward_rounded;
          lineColor = Colors.purple.shade600;
          break;
        case 'Child':
          iconData = Icons.arrow_downward_rounded;
          lineColor = Colors.indigo.shade600;
          break;
        case 'Mentor':
          iconData = Icons.school_rounded;
          lineColor = Colors.blue.shade600;
          break;
        case 'Rival':
          iconData = Icons.bolt_rounded;
          lineColor = Colors.red.shade800;
          break;
        case 'Colleague':
          lineColor = Colors.green.shade600;
          break;
        case 'Mentee':
          iconData = Icons.face_rounded;
          lineColor = Colors.orange.shade600;
          break;
        default:
          lineColor = Colors.blueGrey;
          iconData = null;
          break;
      }

      paint.color = lineColor;
      paint.strokeWidth = strokeWidth;

      // Calculate start point on the center node's perimeter (perimeter of the square box)
      final startPoint = _getPerimeterPoint(
        centerPoint,
        targetCenter,
        nodeDim / 2,
      );

      // Calculate end point on the target node's perimeter
      final targetPoint = _getPerimeterPoint(
        targetCenter,
        centerPoint, // The direction is from the target *towards* the center
        nodeDim / 2,
      );

      // Draw the line
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(targetPoint.dx, targetPoint.dy); // Draw a straight line
      canvas.drawPath(path, paint);

      // --- NEW ICON LOGIC ---
      if (iconData != null) {
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: String.fromCharCode(iconData.codePoint),
            style: TextStyle(
              fontSize: 20.0, // Icon size
              fontFamily: iconData.fontFamily,
              color: lineColor,
            ),
          ),
        );
        textPainter.layout();

        // --- Bring the icon back from the edge ---
        // The distance to pull the icon back from the node edge.
        const double pullBackDistance = 15.0;
        final Offset directionVector = startPoint - targetPoint;
        final double distance = directionVector.distance;

        // Calculate the new center for the icon, pulled back along the line.
        final Offset iconCenter = distance > 0
            ? targetPoint + (directionVector / distance) * pullBackDistance
            : targetPoint;

        // Position the icon so its center is at the new iconCenter
        final iconOffset = Offset(
          iconCenter.dx - textPainter.width / 2,
          iconCenter.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, iconOffset);
      }
    }
  }

  // Calculates the perimeter point on the center node towards the target point
  // It calculates the intersection with the square boundary, not a circle.
  Offset _getPerimeterPoint(Offset center, Offset target, double halfDim) {
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    // Check if the target is the center itself (should not happen, but for safety)
    if (dx == 0 && dy == 0) return center;

    // Calculate the ratios of distance to half-dimension
    final double ratioX = dx != 0 ? (dx / halfDim).abs() : 0;
    final double ratioY = dy != 0 ? (dy / halfDim).abs() : 0;

    // The scale factor is determined by the larger ratio (the edge hit first)
    final double scale = (ratioX > 0 || ratioY > 0)
        ? 1 / max(ratioX, ratioY)
        : 1;

    // Return the intersection point on the square perimeter
    return Offset(center.dx + dx * scale, center.dy + dy * scale);
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    // Only repaint if the character list, relations, or node positions change.
    return oldDelegate.center != center ||
        oldDelegate.external != external ||
        oldDelegate.relations != relations ||
        oldDelegate.nodePositions != nodePositions;
  }
}

// =================================================================
// 7. NEW WEB PAINTER
// =================================================================

class WebPainter extends CustomPainter {
  final Offset center;
  final List<double> radii;

  WebPainter({required this.center, required this.radii});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha((255 * 0.2).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Draw radial lines (8 directions)
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4); // 45 degrees each
      final endX = center.dx + radii.last * cos(angle);
      final endY = center.dy + radii.last * sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }

    // 2. Draw concentric rings connecting the radials
    for (final radius in radii) {
      final path = Path();
      for (int i = 0; i <= 8; i++) {
        final angle = i * (pi / 4);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // To make it look more like a web, we can use quadratic bezier curves
          // instead of straight lines. Let's find the previous point.
          final prevAngle = (i - 1) * (pi / 4);

          // Control point is slightly sagged towards the center
          final controlRadius = radius * 0.95; // Sag factor
          final controlX =
              center.dx + controlRadius * cos((angle + prevAngle) / 2);
          final controlY =
              center.dy + controlRadius * sin((angle + prevAngle) / 2);

          path.quadraticBezierTo(controlX, controlY, x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WebPainter oldDelegate) => false;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Using a rounded container for the line indicator
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
