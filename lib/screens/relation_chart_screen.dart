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

class _RelationChartScreenState extends State<RelationChartScreen> {
  final double nodeDim = 180.0;
  final double buttonDim = 50.0;

  List<Character> _characters = [];
  List<Link> _relations = [];
  Map<dynamic, Offset> _nodePositions = {};

  final TransformationController _transformationController =
      TransformationController();

  late Box<Character> _characterBox;
  late Box<Link> _linkBox;

  // Track the current scale for the Slider's value
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Listener to update the Slider value when InteractiveViewer is manually zoomed
    _transformationController.addListener(_onTransformationUpdate);
  }

  void _onTransformationUpdate() {
    // The scale factor is typically stored at index 0 of the Matrix4's storage array
    final newScale = _transformationController.value.storage[0];
    if (_currentScale != newScale) {
      setState(() {
        _currentScale = newScale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationUpdate);
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _characterBox = Hive.box<Character>('characters');
    _linkBox = Hive.box<Link>('links');

    final centerNode = _characterBox.get(widget.startCharacterKey);
    if (centerNode == null) return;

    // Find all links connected to the center node
    final connectedLinks = _linkBox.values.where((link) {
      return (link.entity1Key == centerNode.key &&
              link.entity1IterationIndex == widget.iterationIndex) ||
          (link.entity2Key == centerNode.key &&
              link.entity2IterationIndex == widget.iterationIndex);
    }).toList();

    final charactersOnScreen = <Character>{centerNode};
    for (final link in connectedLinks) {
      final otherKey = link.entity1Key == centerNode.key
          ? link.entity2Key
          : link.entity1Key;
      final otherChar = _characterBox.get(otherKey);
      if (otherChar != null) {
        charactersOnScreen.add(otherChar);
      }
    }

    setState(() {
      _characters = charactersOnScreen.toList();
      _relations = connectedLinks;

      // Load saved positions from the center node, or initialize to empty map
      final savedLayout = _centerNode?.relationWebLayout;
      if (savedLayout != null) {
        _nodePositions = savedLayout.map(
          (key, value) => MapEntry(key, Offset(value['dx']!, value['dy']!)),
        );
      } else {
        _nodePositions = {};
      }
    });

    // Auto-layout on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only auto-layout if no positions were loaded
      if (_nodePositions.isEmpty) {
        _autoLayout();
      }
      // Always center the view on launch, regardless of whether we loaded a layout or created one.
      _resetAndCenterView();
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
    centerNode.relationWebLayout = savableLayout;
    await centerNode.save();
  }

  // Helper to get the center node instance
  Character? get _centerNode => _characters.firstWhere(
    (c) => c.key == widget.startCharacterKey,
    orElse: () {
      final char = _characterBox.get(widget.startCharacterKey);
      if (char == null) throw StateError('Center character not found!');
      return char;
    },
  );

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
        characterBox: _characterBox,
        existingCharacterKeys: _characters.map((c) => c.key).toSet(),
        onCharacterSelected: (char, iterationIndex) {
          _addCharacter(char, relationType, direction, iterationIndex);
        },
      ),
    );
  }

  // Adds a new character and relation
  void _addCharacter(
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
      _characters.add(char);
      _relations.add(newLink);
    });

    _autoLayout();
  }

  void _deleteNode(Character charToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Node'),
        content: Text(
          'Are you sure you want to delete the node for "${charToDelete.name}"?',
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

    // Find and delete the link
    final linkToDelete = _relations.firstWhere(
      (link) =>
          link.entity2Key == charToDelete.key ||
          link.entity1Key == charToDelete.key,
      orElse: () => throw StateError('Link not found for character to delete'),
    );
    await _linkBox.delete(linkToDelete.key);

    setState(() {
      _characters.remove(charToDelete);
      _relations.remove(linkToDelete);
      _nodePositions.remove(charToDelete.key);
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
    for (final link in _relations) {
      await _linkBox.delete(link.key);
    }

    // Reset state
    setState(() {
      _characters.removeWhere((char) => char.key != _centerNode?.key);
      _relations.clear();
      _nodePositions.clear();
    });
  }

  // Handles drag update
  void _onNodeDrag(DragUpdateDetails details, Character char) {
    // Allow free dragging during the pan update for visual feedback
    setState(() {
      final currentPos = _nodePositions[char.key] ?? Offset.zero;
      _nodePositions[char.key] = currentPos + details.delta;
    });
  }

  // NEW: Snap-to-grid logic on drag end
  void _onNodeDragEnd(DragEndDetails details, Character char) {
    final canvasSize = Size(
      MediaQuery.of(context).size.width * 5,
      MediaQuery.of(context).size.height * 5,
    );
    final currentPos = _nodePositions[char.key] ?? Offset.zero;

    // Generate all possible hook points
    final allHookPoints = _generateWebHookPoints(
      canvasSize,
      // Generate enough rings to accommodate all current nodes, plus a few extra for snapping.
      // This ensures that if the user drags a node, there are empty spots to snap to.
      numberOfRings:
          _characters.where((c) => c.key != _centerNode?.key).length + 3,
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
      _nodePositions[char.key] = closestPoint;
      _saveLayout(); // Save layout after snapping
    });
  }

  // Auto-sorts the external nodes to their calculated directional positions
  void _autoLayout() {
    final canvasSize = Size(
      MediaQuery.of(context).size.width * 5,
      MediaQuery.of(context).size.height * 5,
    ); // This variable is used in _generateWebHookPoints
    final centerKey = _centerNode?.key;
    if (centerKey == null) return;

    final directionToChars = <String, List<Character>>{};

    // Correctly handle bidirectional relationships
    for (final rel in _relations) {
      dynamic otherKey;

      if (rel.entity1Key == centerKey) {
        otherKey = rel.entity2Key;
      } else if (rel.entity2Key == centerKey) {
        otherKey = rel.entity1Key;
        // If the center node is entity2, we might need to find the inverse relationship
        // to get the correct direction from the center node's perspective.
        // This part depends on how your RelationshipService is implemented.
        // For now, we assume the description is universal or we'll add inverse logic.
      } else {
        continue; // This relation doesn't involve the center node
      }

      // Use the corrected relation description to find the direction
      final direction = _getDirectionForRelation(
        _getRelationDescription(rel, centerKey),
      );

      final otherChar = _characters.firstWhere(
        (c) => c.key == otherKey,
        orElse: () =>
            Character(name: 'Unknown', parentProjectId: -1), // Failsafe
      );

      if (otherChar.name != 'Unknown') {
        (directionToChars[direction] ??= []).add(otherChar);
      }
    }

    // Determine the maximum number of rings needed for the web
    int maxRelationsInOneDirection = 0;
    directionToChars.forEach((_, chars) {
      if (chars.length > maxRelationsInOneDirection) {
        maxRelationsInOneDirection = chars.length;
      }
    });

    // Generate the hook points on the web
    final hookPoints = _generateWebHookPoints(
      canvasSize,
      numberOfRings: maxRelationsInOneDirection,
    );
    final newPositions = Map<dynamic, Offset>.from(_nodePositions);

    directionToChars.forEach((direction, chars) {
      final pointsForDirection = hookPoints[direction] ?? [];
      for (int i = 0; i < chars.length; i++) {
        if (i >= pointsForDirection.length) break; // Safety check

        final char = chars[i];
        newPositions[char.key] = pointsForDirection[i];
      }
    });

    setState(() {
      _nodePositions = newPositions;
      _saveLayout(); // Save the new layout after auto-sorting
    });
  }

  String _getDirectionForRelation(String relationType) {
    const Map<String, String> relationToDirection = {
      'Parent': 'top', // This was correct
      'Rival': 'top-left',
      'Sibling': 'top-right',
      'Friend': 'left',
      'Spouse': 'right',
      'Mentor': 'bottom-left',
      'Child': 'bottom', // This was correct
      'Mentee': 'bottom-right',
    };
    return relationToDirection[relationType] ?? 'bottom';
  }

  void _resetAndCenterView() {
    final canvasSize = Size(
      MediaQuery.of(context).size.width * 5,
      MediaQuery.of(context).size.height * 5,
    );
    // Calculate the translation needed to move the center node's center (canvasCenter)
    // to the InteractiveViewer's center. The InteractiveViewer's center is (0,0) in world space
    // when unscaled and untranslated. The target center of the node is (canvasSize.width / 2, canvasSize.height / 2).

    // We want the current view center (0,0 in screen space) to look at the node center.
    // The required matrix is simply the inverse of the node's position.
    final double targetX = canvasSize.width / 2;
    final double targetY = canvasSize.height / 2;

    // Matrix to translate the view to put (targetX, targetY) at the screen's center
    final matrix = Matrix4.translationValues(
      -targetX + MediaQuery.of(context).size.width / 2,
      -targetY + MediaQuery.of(context).size.height / 2,
      0.0,
    )..scale(Vector3(1.0, 1.0, 1.0));

    _transformationController.value = matrix;
  }

  void _resetZoom() {
    final currentMatrix = _transformationController.value;
    // Get the current translation vector
    final Vector3 currentTranslation = currentMatrix.getTranslation();

    // Create a new matrix with the same translation but a scale of 1.0
    final matrix = Matrix4.translation(currentTranslation)
      ..scale(Vector3(1.0, 1.0, 1.0));
    _transformationController.value = matrix;
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

    final nodeWidget = GestureDetector(
      onPanUpdate: (details) => _onNodeDrag(details, char),
      onPanEnd: (details) =>
          _onNodeDragEnd(details, char), // Use new snap logic
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
              color: Colors.black.withOpacity(0.2),
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
                        char.name, // This was correct
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        char.occupation ?? 'No occupation',
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
                    isCenter ? _deleteAllNodes() : _deleteNode(char);
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
    );

    if (isCenter) {
      return nodeWidget;
    }

    return Positioned(
      left: _nodePositions[char.key]?.dx ?? 0.0,
      top: _nodePositions[char.key]?.dy ?? 0.0,
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
    final screenSize = MediaQuery.of(context).size;

    final canvasSize = Size(screenSize.width * 5, screenSize.height * 5);
    // Calculate the position for the central group (centered on canvas)
    final double centerGroupX = canvasSize.width / 2 - nodeDim / 2;
    final double centerGroupY = canvasSize.height / 2 - nodeDim / 2;
    final centerGroupOffset = Offset(centerGroupX, centerGroupY);

    // Filter out the center node for easier iteration
    final externalCharacters = _characters.where(
      (c) => c.key != widget.startCharacterKey,
    );

    final centerChar = _centerNode;

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
        title: Text(centerChar != null ? centerChar.name : "Loading..."),
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
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            children: [
              // NEW: Draw the background web
              Positioned.fill(
                child: CustomPaint(
                  painter: WebPainter(
                    center: Offset(canvasSize.width / 2, canvasSize.height / 2),
                    // Generate radii based on the current layout needs
                    radii:
                        _generateWebHookPoints(
                              canvasSize, // Determine the number of rings needed based on the character with the most links
                              numberOfRings:
                                  _characters
                                      .where((c) => c.key != _centerNode?.key)
                                      .length +
                                  1,
                            ).values.first
                            .map(
                              (p) =>
                                  (p -
                                          Offset(
                                            canvasSize.width / 2 - nodeDim / 2,
                                            canvasSize.height / 2 - nodeDim / 2,
                                          ))
                                      .distance,
                            )
                            .toList(),
                  ),
                ),
              ),
              // 1. CustomPainter for Lines (Canvas)
              if (centerChar != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: RelationPainter(
                      center: centerChar,
                      external: externalCharacters.toList(),
                      relations: _relations,
                      nodePositions: _nodePositions,
                      nodeDim: nodeDim,
                      // Pass the center point of the central node on the canvas
                      canvasCenter: Offset(
                        canvasSize.width / 2,
                        canvasSize.height / 2,
                      ),
                      getRelationDescription: _getRelationDescription,
                    ),
                  ),
                ),

              // 2. Central Group (Main Node and Buttons)
              _buildCentralGroup(centerGroupOffset),

              // 3. External Character Nodes
              ...externalCharacters.map(
                (char) => _nodePositions.containsKey(char.key)
                    ? _buildNode(char, false)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
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
              child: Slider(
                // FIXED: Read the current scale factor from the matrix (storage[0])
                value: _currentScale.clamp(0.1, 2.5),
                min: 0.1,
                max: 2.5,
                onChanged: (newScale) {
                  final currentMatrix = _transformationController.value;

                  // Get current translation values from storage
                  final double tx = currentMatrix.storage[12];
                  final double ty = currentMatrix.storage[13];

                  // Create a new matrix by applying translation first, then scale
                  final newMatrix = Matrix4.translationValues(tx, ty, 0.0)
                    ..scale(Vector3(newScale, newScale, newScale));

                  _transformationController.value = newMatrix;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Center View (Reset Position and Zoom)',
              onPressed: _resetAndCenterView,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: 'Reset Zoom (Keep Position)',
              onPressed: _resetZoom,
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
      'Acquaintance': {'color': Colors.grey},
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
  final Box<Character> characterBox;
  final Set<dynamic> existingCharacterKeys;
  final Function(Character, int?) onCharacterSelected;

  const _AddRelationDialog({
    required this.relationType,
    required this.characterBox,
    required this.existingCharacterKeys,
    required this.onCharacterSelected,
  });

  @override
  State<_AddRelationDialog> createState() => _AddRelationDialogState();
}

class _AddRelationDialogState extends State<_AddRelationDialog> {
  String _view = 'character'; // 'character' or 'iteration'
  Character? _selectedCharacter;

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
      final selectableChars = widget.characterBox.values
          .where((c) => !widget.existingCharacterKeys.contains(c.key))
          .toList();

      if (selectableChars.isEmpty) {
        return const Text('No more characters available to add.');
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
            subtitle: Text(char.occupation ?? 'No occupation'),
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
      final otherKey = rel.entity1Key == center.key
          ? rel.entity2Key
          : rel.entity1Key; // Get the key of the other character

      // Find the character linked to the center node
      final targetChar = external.firstWhere(
        (c) => c.key == otherKey,
        orElse: () => Character(name: 'Unknown', parentProjectId: -1),
      );

      // Skip if the target position hasn't been calculated yet
      if (!nodePositions.containsKey(targetChar.key)) continue;

      // Calculate the center point of the external node on the canvas
      final targetCenter = Offset(
        (nodePositions[targetChar.key]?.dx ?? 0) + nodeDim / 2,
        (nodePositions[targetChar.key]?.dy ?? 0) + nodeDim / 2,
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
