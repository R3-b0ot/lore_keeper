import 'package:hive/hive.dart';
import 'package:lore_keeper/screens/trait_editor_screen.dart';
part 'trait_service.g.dart';

class TraitService {
  late final Box<SimpleTrait> _customTraitsBox;

  TraitService() {
    _customTraitsBox = Hive.box<SimpleTrait>('custom_traits');
  }

  // --- Load Custom Traits ---
  Map<String, List<SimpleTrait>> loadCustomTraits() {
    final Map<String, List<SimpleTrait>> customTraits = {
      'congenital': [],
      'physical': [],
      'coping': [],
    };

    for (final trait in _customTraitsBox.values) {
      // The 'type' property needs to be stored on the SimpleTrait model
      // to know which list to add it to. Let's assume it's there.
      if (trait.type == 'congenital') {
        customTraits['congenital']!.add(trait);
      } else if (trait.type == 'physical') {
        customTraits['physical']!.add(trait);
      }
    }
    return customTraits;
  }

  // --- Add or Update a Custom Trait ---
  Future<void> saveCustomTrait(SimpleTrait trait) async {
    // Use a composite key to ensure uniqueness and allow updates.
    // e.g., "congenital_Melancholic"
    final key = '${trait.type}_${trait.name}';
    await _customTraitsBox.put(key, trait);
  }

  // --- Delete a Custom Trait ---
  Future<void> deleteCustomTrait(SimpleTrait trait) async {
    final key = '${trait.type}_${trait.name}';
    await _customTraitsBox.delete(key);
  }

  // --- Update a Trait (handles name changes) ---
  Future<void> updateCustomTrait(
    SimpleTrait oldTrait,
    SimpleTrait newTrait,
  ) async {
    // If the name (and thus the key) has changed, we need to delete the old
    // entry and create a new one.
    if (oldTrait.name != newTrait.name || oldTrait.type != newTrait.type) {
      final oldKey = '${oldTrait.type}_${oldTrait.name}';
      await _customTraitsBox.delete(oldKey);
    }
    // Save the new/updated trait.
    await saveCustomTrait(newTrait);
  }
}

// We need to adapt the SimpleTrait model to support this.
// Let's add a 'type' field. This change will be in trait_editor_screen.dart

@HiveType(typeId: 12) // Use an unused typeId
class CustomTraitAdapter extends TypeAdapter<SimpleTrait> {
  @override
  final int typeId = 12; // Ensure this matches the annotation

  @override
  SimpleTrait read(BinaryReader reader) {
    final fields = reader.readMap();
    return SimpleTrait.fromJson(fields.cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, SimpleTrait obj) {
    writer.writeMap(obj.toJson());
  }
}
