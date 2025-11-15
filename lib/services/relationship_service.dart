import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class RelationshipService {
  static final RelationshipService _instance = RelationshipService._internal();
  factory RelationshipService() => _instance;

  Map<String, dynamic> _inversions = {};
  bool _isInitialized = false;

  RelationshipService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/relationship_inversions.json',
      );
      _inversions = json.decode(jsonString);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading relationship inversions: $e');
    }
  }

  List<String> getRelationshipsForType(String entityType) {
    if (!_isInitialized || !_inversions.containsKey(entityType)) {
      return [];
    }
    final List<String> relationships = [];
    final typeData = _inversions[entityType] as Map<String, dynamic>;

    if (typeData.containsKey('symmetrical')) {
      relationships.addAll((typeData['symmetrical'] as List).cast<String>());
    }

    if (typeData.containsKey('asymmetrical')) {
      relationships.addAll(
        (typeData['asymmetrical'] as Map).keys.cast<String>(),
      );
    }

    relationships.sort();
    return relationships;
  }

  String getInverse(String description) {
    if (!_isInitialized) return description; // Failsafe

    // Search through all categories
    for (var entityType in _inversions.keys) {
      final typeData = _inversions[entityType] as Map<String, dynamic>;

      // Check symmetrical
      if ((typeData['symmetrical'] as List?)?.contains(description) ?? false) {
        return description;
      }

      // Check asymmetrical
      final asymmetrical = typeData['asymmetrical'] as Map<String, dynamic>?;
      if (asymmetrical != null && asymmetrical.containsKey(description)) {
        return asymmetrical[description]!;
      }
    }
    return description; // Return self if no inverse is found
  }

  List<String> getAllRelationshipTypes() {
    if (!_isInitialized) return [];

    final Set<String> allTypes = {};
    _inversions.forEach((entityType, typeData) {
      final data = typeData as Map<String, dynamic>;
      if (data.containsKey('symmetrical')) {
        allTypes.addAll((data['symmetrical'] as List).cast<String>());
      }
      if (data.containsKey('asymmetrical')) {
        allTypes.addAll((data['asymmetrical'] as Map).keys.cast<String>());
      }
    });
    return allTypes.toList()..sort();
  }
}
