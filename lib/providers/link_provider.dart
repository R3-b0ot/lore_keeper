import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'dart:async';

class LinkProvider with ChangeNotifier {
  late Box<Link> _linkBox;
  StreamSubscription? _boxSubscription;
  final RelationshipService _relationshipService = RelationshipService();

  LinkProvider() {
    _linkBox = Hive.box<Link>('links');
    _boxSubscription = _linkBox.watch().listen((event) {
      // For simplicity, we'll just reload all links for the character
      // when any link changes. A more optimized approach could check the event key.
      // This requires knowing which character is currently active.
      // We will handle the filtering in the module itself.
      notifyListeners();
    });
  }

  List<Link> getLinksForEntity(dynamic entityKey) {
    return _linkBox.values
        .where((link) => link.entity1Key == entityKey)
        .toList();
  }

  List<Link> getLinksForIteration(dynamic entityKey, int iterationIndex) {
    return _linkBox.values
        .where(
          (link) =>
              (link.entity1Key == entityKey &&
                  link.entity1IterationIndex == iterationIndex) ||
              (link.entity2Key == entityKey &&
                  link.entity2IterationIndex == iterationIndex),
        )
        .toList();
  }

  Future<void> addLink(Link newLink) async {
    // Get the inverse description
    final inverseDescription = _relationshipService.getInverse(
      newLink.description,
    );

    // Create the inverse link
    final inverseLink = Link()
      ..entity1Type = newLink.entity2Type
      ..entity1Key = newLink.entity2Key
      ..entity2Type = newLink.entity1Type
      ..entity2Key = newLink.entity1Key
      ..description = inverseDescription
      ..date = newLink.date
      ..entity1IterationIndex = newLink.entity2IterationIndex
      ..entity2IterationIndex = newLink.entity1IterationIndex;

    // Add both links to the box
    await _linkBox.add(newLink);
    await _linkBox.add(inverseLink);

    notifyListeners();
  }

  Future<void> updateLink(Link link) async {
    await link.save();

    // Also update the inverse link
    // The logic for finding and updating the inverse link needs to be re-evaluated
    // For now, this part is commented out to resolve the error.
    notifyListeners();
  }

  Future<void> deleteLink(Link link) async {
    await link.delete();
    notifyListeners();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    super.dispose();
  }
}
