import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/services/trait_service.dart';
import 'package:lore_keeper/widgets/keyboard_aware_dialog.dart';

// --- 1. Data Models ---

// Model for simple traits (Congenital, Physical)
@HiveType(typeId: 9) // Assign a unique typeId
class SimpleTrait {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String icon;
  @HiveField(2)
  final String explanation;
  @HiveField(3)
  final String type; // 'congenital' or 'physical'

  SimpleTrait({
    required this.name,
    required this.icon,
    required this.explanation,
    this.type = 'congenital', // Default type
  });

  // Factory constructor for creating a new SimpleTrait instance from a map.
  factory SimpleTrait.fromJson(Map<String, dynamic> json) {
    return SimpleTrait(
      name: json['name'] as String,
      icon: json['icon'] as String,
      explanation: json['explanation'] as String,
      type: json['type'] as String? ?? 'congenital', // Provide a default value
    );
  }

  // Method for converting a SimpleTrait instance to a map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'explanation': explanation,
      'type': type,
    };
  }
}

// Model for personality traits (Dichotomous, Spectrum)
class PersonalityTrait {
  final String groupName;
  final List<TraitOption> options;

  PersonalityTrait({required this.groupName, required this.options});
}

class TraitOption {
  final String name;
  final int value;
  final String icon;
  final String explanation;

  TraitOption({
    required this.name,
    required this.value,
    required this.icon,
    required this.explanation,
  });
}

// --- 2. Trait Data Structure (Complete) ---

final Map<String, dynamic> traitData = {
  'personality': [
    // --- Dichotomous (2 Choices) ---
    PersonalityTrait(
      groupName: "Temper",
      options: [
        TraitOption(
          name: "Calm",
          value: 1,
          icon: "🧘",
          explanation: "Remains serene and composed under pressure.",
        ),
        TraitOption(
          name: "Wrathful",
          value: -1,
          icon: "🔥",
          explanation: "Prone to intense anger and violent outbursts.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Faith",
      options: [
        TraitOption(
          name: "Pious",
          value: 1,
          icon: "🙏",
          explanation:
              "Deeply devout, showing reverence and strict obedience to faith.",
        ),
        TraitOption(
          name: "Cynical",
          value: -1,
          icon: "🧐",
          explanation: "Distrustful of faith and the motives of others.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Ambition",
      options: [
        TraitOption(
          name: "Ambitious",
          value: 1,
          icon: "🚀",
          explanation: "Driven by a strong desire for power and success.",
        ),
        TraitOption(
          name: "Content",
          value: -1,
          icon: "🏡",
          explanation:
              "Satisfied with their current station and avoids seeking power.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Generosity",
      options: [
        TraitOption(
          name: "Generous",
          value: 1,
          icon: "🎁",
          explanation:
              "Willing to give freely and shares resources with others.",
        ),
        TraitOption(
          name: "Greedy",
          value: -1,
          icon: "💰",
          explanation:
              "Hoards wealth and resources, often at the expense of others.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Diligence",
      options: [
        TraitOption(
          name: "Diligent",
          value: 1,
          icon: "⚙️",
          explanation:
              "Hard-working, persistent, and meticulously attends to duties.",
        ),
        TraitOption(
          name: "Slothful",
          value: -1,
          icon: "😴",
          explanation: "Lazy, avoids work, and finds duties tiresome.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Purity",
      options: [
        TraitOption(
          name: "Chaste",
          value: 1,
          icon: "🌸",
          explanation: "Avoids carnal pleasures and sensual excess.",
        ),
        TraitOption(
          name: "Lustful",
          value: -1,
          icon: "❤️‍🔥",
          explanation: "Driven by strong, often overwhelming, carnal desires.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Honesty",
      options: [
        TraitOption(
          name: "Honest",
          value: 1,
          icon: "🗣️",
          explanation: "Truthful and straightforward in action and word.",
        ),
        TraitOption(
          name: "Deceitful",
          value: -1,
          icon: "🤥",
          explanation: "Prone to lies, manipulation, and hiding the truth.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Warlikeness",
      options: [
        TraitOption(
          name: "Bellicose",
          value: 1,
          icon: "⚔️",
          explanation: "Eager to fight, aggressive, and war-like.",
        ),
        TraitOption(
          name: "Dovish",
          value: -1,
          icon: "🕊️",
          explanation: "Prefers peace and strongly opposes military conflict.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Justice",
      options: [
        TraitOption(
          name: "Just",
          value: 1,
          icon: "⚖️",
          explanation: "Fair, impartial, and motivated by righteousness.",
        ),
        TraitOption(
          name: "Arbitrary",
          value: -1,
          icon: "❌",
          explanation: "Acts without consideration for laws or fairness.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Cunning",
      options: [
        TraitOption(
          name: "Shrewd",
          value: 1,
          icon: "🦊",
          explanation: "Highly clever, practical, and sharp-witted.",
        ),
        TraitOption(
          name: "Simpleton",
          value: -1,
          icon: "🎈",
          explanation: "Lacking in common sense or intellectual complexity.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Humility",
      options: [
        TraitOption(
          name: "Humble",
          value: 1,
          icon: "⬇️",
          explanation:
              "Modest and not overly preoccupied with their own importance.",
        ),
        TraitOption(
          name: "Arrogant",
          value: -1,
          icon: "👑",
          explanation: "Possesses an overbearing sense of superiority.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Sociability",
      options: [
        TraitOption(
          name: "Gregarious",
          value: 1,
          icon: "🎉",
          explanation:
              "Loves company, highly social, and enjoys being around people.",
        ),
        TraitOption(
          name: "Reclusive",
          value: -1,
          icon: "⛰️",
          explanation: "Prefers solitude and avoids social interaction.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Austerity",
      options: [
        TraitOption(
          name: "Temperate",
          value: 1,
          icon: "💧",
          explanation: "Practices moderation and self-restraint.",
        ),
        TraitOption(
          name: "Gluttonous",
          value: -1,
          icon: "🍔",
          explanation: "Excessive consumer of food and drink.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Patience",
      options: [
        TraitOption(
          name: "Patient",
          value: 1,
          icon: "⏳",
          explanation: "Endures waiting or suffering without complaint.",
        ),
        TraitOption(
          name: "Fretful",
          value: -1,
          icon: "😬",
          explanation:
              "Anxious, irritable, and easily worried by small things.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Familiarity",
      options: [
        TraitOption(
          name: "Familiar",
          value: 1,
          icon: "👨‍👩‍👧",
          explanation: "Prioritizes family bonds and kin over all others.",
        ),
        TraitOption(
          name: "Cold",
          value: -1,
          icon: "🥶",
          explanation:
              "Emotionally detached and shows little affection or warmth.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Forgiveness",
      options: [
        TraitOption(
          name: "Forgiving",
          value: 1,
          icon: "🤝",
          explanation: "Ready to pardon others and let go of grudges.",
        ),
        TraitOption(
          name: "Vengeful",
          value: -1,
          icon: "🔪",
          explanation: "Driven to seek retribution for perceived injuries.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Trust",
      options: [
        TraitOption(
          name: "Trusting",
          value: 1,
          icon: "🤗",
          explanation:
              "Tends to believe in the good intentions and reliability of others.",
        ),
        TraitOption(
          name: "Paranoid",
          value: -1,
          icon: "👀",
          explanation:
              "Suspicious and distrustful, often expecting betrayal or harm.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Orderliness",
      options: [
        TraitOption(
          name: "Methodical",
          value: 1,
          icon: "📋",
          explanation:
              "Prefers structure, planning, and systematic approaches.",
        ),
        TraitOption(
          name: "Chaotic",
          value: -1,
          icon: "💥",
          explanation:
              "Unpredictable and disorganized; thrives in or creates disorder.",
        ),
      ],
    ),

    // --- Spectrum (3 Choices) ---
    PersonalityTrait(
      groupName: "Empathy",
      options: [
        TraitOption(
          name: "Compassionate",
          value: 1,
          icon: "💖",
          explanation: "Feels sympathy and pity for the suffering of others.",
        ),
        TraitOption(
          name: "Apathetic",
          value: 0,
          icon: "😶",
          explanation: "Indifferent, lacking emotion or interest in others.",
        ),
        TraitOption(
          name: "Sadistic",
          value: -1,
          icon: "🥀",
          explanation:
              "Derives pleasure from inflicting pain or suffering on others.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Courage",
      options: [
        TraitOption(
          name: "Brave",
          value: 1,
          icon: "🛡️",
          explanation: "Unafraid to act, even in the face of danger.",
        ),
        TraitOption(
          name: "Normal",
          value: 0,
          icon: "🧍",
          explanation: "Possesses an average level of courage.",
        ),
        TraitOption(
          name: "Craven",
          value: -1,
          icon: "👻",
          explanation: "Easily intimidated and hesitant in the face of danger.",
        ),
      ],
    ),
    PersonalityTrait(
      groupName: "Reliability",
      options: [
        TraitOption(
          name: "Fickle",
          value: -2,
          icon: "💨",
          explanation: "Changes their mind or loyalties frequently.",
        ),
        TraitOption(
          name: "Reliable",
          value: 1,
          icon: "✅",
          explanation: "Loyal, dependable, and predictable in action.",
        ),
        TraitOption(
          name: "Stubborn",
          value: -1,
          icon: "⛰️",
          explanation: "Resistance to change and determined in their actions.",
        ),
        TraitOption(
          name: "Eccentric",
          value: 0,
          icon: "🌀",
          explanation:
              "Behaves unconventionally, often perceived as strange or erratic.",
        ),
      ],
    ),
  ],

  // --- Congenital or Inherited Traits (Multi-select) ---
  'congenital': [
    SimpleTrait(
      name: "Melancholic",
      icon: "🌧️",
      explanation: "This character has a hard time seeing the good in life.",
    ),
    SimpleTrait(
      name: "Lunatic",
      icon: "🌕",
      explanation:
          "Plagued by hallucinations, delusions and disorganized thoughts...",
    ),
    SimpleTrait(
      name: "Possessed",
      icon: "😈",
      explanation: "The sudden changes in emotion, awareness and ability...",
    ),
    SimpleTrait(
      name: "Fecund",
      icon: "👶",
      explanation:
          "This character is highly fertile and likely to produce many offspring.",
    ),
    SimpleTrait(
      name: "Albino",
      icon: "🤍",
      explanation: "A striking lack of pigment in hair, skin, and eyes.",
    ),
    SimpleTrait(
      name: "Hunchback",
      icon: "🚶",
      explanation:
          "A physical deformity causing a noticeable curvature of the spine.",
    ),
    SimpleTrait(
      name: "Clubfooted",
      icon: "👣",
      explanation: "A congenital deformity of the foot.",
    ),
    SimpleTrait(
      name: "Lisping",
      icon: "👅",
      explanation: "An articulation impediment affecting pronunciation.",
    ),
    SimpleTrait(
      name: "Stuttering",
      icon: "🗣️",
      explanation:
          "A speech disorder involving frequent problems with the normal flow and pattern of speaking.",
    ),
    SimpleTrait(
      name: "Wroth",
      icon: "💢",
      explanation:
          "Quick to anger, often violent, with little patience for others.",
    ),
    SimpleTrait(
      name: "Giant",
      icon: "🧍",
      explanation:
          "Towers over most, possessing immense strength but often facing social and physical challenges.",
    ),
    SimpleTrait(
      name: "Dwarf",
      icon: "⚒️",
      explanation:
          "Significantly shorter and stockier than average, often resilient and strong for their size.",
    ),
    SimpleTrait(
      name: "Ambidextrous",
      icon: "✍️",
      explanation:
          "Equally adept at using both hands, a rare and useful skill.",
    ),
    SimpleTrait(
      name: "Pure-blooded",
      icon: "🩸",
      explanation:
          "Descends from a historically significant and unmixed lineage, carrying social weight.",
    ),
    SimpleTrait(
      name: "Twin",
      icon: "♊",
      explanation:
          "Born as one of a pair, sharing a unique and sometimes mysterious bond.",
    ),
    SimpleTrait(
      name: "Barren/Sterile",
      icon: "🚫",
      explanation:
          "Unable to produce offspring, which can have significant social and dynastic implications.",
    ),
    SimpleTrait(
      name: "Heterochromia",
      icon: "👁️",
      explanation:
          "Possesses two different colored eyes, often seen as mysterious or unnatural.",
    ),
  ],

  // --- Leveled Congenital Traits (Single-select per group) ---
  'leveled': {
    'Appearance': [
      SimpleTrait(
        name: "Disfigured",
        icon: "🎭",
        explanation: "Severely deformed or scarred...",
      ),
      SimpleTrait(
        name: "Hideous",
        icon: "👺",
        explanation: "A terrifying visage that can repel onlookers.",
      ),
      SimpleTrait(
        name: "Ugly",
        icon: "🤕",
        explanation: "A markedly unpleasant or flawed appearance.",
      ),
      SimpleTrait(
        name: "Homely",
        icon: "😐",
        explanation: "Plain and unremarkable in appearance.",
      ),
      SimpleTrait(
        name: "Comely",
        icon: "🙂",
        explanation: "Pleasant and good-looking in a simple, modest way.",
      ),
      SimpleTrait(
        name: "Pretty/Handsome",
        icon: "😍",
        explanation: "Strikingly attractive and pleasant to look upon.",
      ),
      SimpleTrait(
        name: "Beautiful",
        icon: "💖",
        explanation: "Stunningly attractive, a true sight to behold.",
      ),
      SimpleTrait(
        name: "Magnificent",
        icon: "💎",
        explanation: "Possesses a truly divine and breathtaking appearance.",
      ),
      SimpleTrait(
        name: "Celestial",
        icon: "🌟",
        explanation:
            "Possesses beauty and grace that defies mortal comprehension...",
      ),
    ],
    'Intelligence': [
      SimpleTrait(
        name: "Incapable",
        icon: "✖️",
        explanation:
            "Unable to comprehend basic concepts or function autonomously.",
      ),
      SimpleTrait(
        name: "Imbecile",
        icon: "🧠",
        explanation: "Severely lacking in mental capacity and understanding.",
      ),
      SimpleTrait(
        name: "Dull",
        icon: "☁️",
        explanation: "Slow-witted and struggles with complex thoughts.",
      ),
      SimpleTrait(
        name: "Slow",
        icon: "🐌",
        explanation: "Takes longer than average to grasp concepts.",
      ),
      SimpleTrait(
        name: "Normal",
        icon: "👤",
        explanation: "Average intellect and common sense.",
      ),
      SimpleTrait(
        name: "Clever",
        icon: "💡",
        explanation: "Quick to learn and understand new ideas.",
      ),
      SimpleTrait(
        name: "Wise",
        icon: "🦉",
        explanation: "Possesses deep insight, knowledge, and good judgment.",
      ),
      SimpleTrait(
        name: "Brilliant",
        icon: "✨",
        explanation: "Exceptional intellectual prowess and genius.",
      ),
      SimpleTrait(
        name: "Transcendent",
        icon: "🌠",
        explanation: "Mind operates on a plane beyond human logic...",
      ),
    ],
    'Physique': [
      SimpleTrait(
        name: "Dead Man/Woman",
        icon: "⚰️",
        explanation: "Barely clings to life; incredibly weak and sickly.",
      ),
      SimpleTrait(
        name: "Feeble",
        icon: "🚶",
        explanation: "Extremely weak; easily exhausted and vulnerable.",
      ),
      SimpleTrait(
        name: "Frail",
        icon: "🦴",
        explanation: "Physically delicate and prone to injury/illness.",
      ),
      SimpleTrait(
        name: "Weak",
        icon: "⬇️",
        explanation: "Below average in physical strength.",
      ),
      SimpleTrait(
        name: "Average",
        icon: "🧍",
        explanation: "Normal physical capability and health.",
      ),
      SimpleTrait(
        name: "Strong",
        icon: "💪",
        explanation: "Has well-developed muscles and great physical power.",
      ),
      SimpleTrait(
        name: "Robust",
        icon: "🛡️",
        explanation: "Exceptional health, stamina, and resilience.",
      ),
      SimpleTrait(
        name: "Mighty",
        icon: "💥",
        explanation: "Possesses near-superhuman strength and vitality.",
      ),
      SimpleTrait(
        name: "Living God",
        icon: "☀️",
        explanation: "Flawless and near-supernatural physical form and health.",
      ),
    ],
  },

  // --- Physical Traits (Multi-select) ---
  'physical': [
    SimpleTrait(
      name: "Obese",
      icon: "🐘",
      explanation: "Severely overweight, impacting speed and stamina.",
    ),
    SimpleTrait(
      name: "Chubby",
      icon: "🐻",
      explanation: "Slightly overweight, having a pleasantly plump body shape.",
    ),
    SimpleTrait(
      name: "Skinny",
      icon: "🍴",
      explanation: "Unduly thin, often lacking in strength.",
    ),
    SimpleTrait(
      name: "Muscular",
      icon: "🏋️",
      explanation: "Well-built, with defined muscle mass.",
    ),
    SimpleTrait(
      name: "Missing Eye",
      icon: "🏴‍☠️",
      explanation: "Has lost an eye, reducing depth perception.",
    ),
    SimpleTrait(
      name: "Missing Limb",
      icon: "🦿",
      explanation: "Has lost an arm or leg, severely impacting mobility.",
    ),
    SimpleTrait(
      name: "Scarred",
      icon: "🩹",
      explanation: "Face or body bears the mark of old wounds.",
    ),
    SimpleTrait(
      name: "Blind",
      icon: "🦯",
      explanation: "Lacks sight entirely.",
    ),
    SimpleTrait(name: "Deaf", icon: "👂", explanation: "Cannot hear sound."),
    SimpleTrait(
      name: "One-Handed",
      icon: "✋",
      explanation: "Has lost use of one hand or arm.",
    ),
    SimpleTrait(name: "Castrated", icon: "✂️", explanation: "Has been gelded."),
    SimpleTrait(
      name: "Eunuch",
      icon: "🚻",
      explanation:
          "A castrated man, historically employed as a guard or official.",
    ),
    SimpleTrait(
      name: "Tattooed",
      icon: "🐉",
      explanation:
          "Body is covered in ink, telling stories or showing allegiance.",
    ),
    SimpleTrait(
      name: "Branded",
      icon: "⚜️",
      explanation: "Marked with a symbol of ownership, shame, or honor.",
    ),
    SimpleTrait(
      name: "Bald",
      icon: "🦲",
      explanation:
          "Lacking hair on the head, either by choice, nature, or affliction.",
    ),
    SimpleTrait(
      name: "Pockmarked",
      icon: "🧫",
      explanation:
          "Skin scarred by disease, leaving a rough and pitted texture.",
    ),
    SimpleTrait(
      name: "Lame",
      icon: "🦵",
      explanation: "Has a permanent injury to a leg, causing a limp.",
    ),
    SimpleTrait(
      name: "Mute",
      icon: "🤐",
      explanation:
          "Unable to speak, due to physical injury or psychological trauma.",
    ),
    SimpleTrait(
      name: "Burned",
      icon: "🔥",
      explanation:
          "Bears severe scars from fire, a permanent reminder of a past event.",
    ),
  ],
};

/// A screen for selecting and managing character traits.
class TraitEditorScreen extends StatefulWidget {
  final Set<String> initialSelectedTraits;
  final Map<String, int> initialPersonalityTraits;
  final Map<String, int> initialLeveledTraits;

  const TraitEditorScreen({
    super.key,
    this.initialSelectedTraits = const {},
    this.initialPersonalityTraits = const {},
    this.initialLeveledTraits = const {},
  });

  @override
  State<TraitEditorScreen> createState() => _TraitEditorScreenState();
}

class _TraitEditorScreenState extends State<TraitEditorScreen>
    with SingleTickerProviderStateMixin {
  // State for selected traits
  late Set<String> _selectedCongenitalTraits;
  late Map<String, int> _selectedPersonalityTraits;
  late Map<String, String> _selectedLeveledTraits;
  late Set<String> _selectedPhysicalTraits;

  late final TraitService _traitService;
  // State for the search functionality
  late final TextEditingController _searchController;
  String _searchQuery = '';

  // Make trait data mutable to allow for custom traits
  late Map<String, dynamic> _dynamicTraitData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _traitService = TraitService();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    try {
      // Initialize mutable trait data from the hardcoded map
      _dynamicTraitData = Map<String, dynamic>.from(
        traitData.map((key, value) {
          if (value is List) {
            return MapEntry(key, List<dynamic>.from(value));
          }
          if (value is Map) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          }
          return MapEntry(key, value);
        }),
      );
      _loadCustomTraits();

      _selectedCongenitalTraits = Set.from(widget.initialSelectedTraits);
      _selectedPhysicalTraits = {}; // Will be populated from congenital traits
      _selectedLeveledTraits = {};
      _selectedPersonalityTraits = Map.from(widget.initialPersonalityTraits);

      // Initialize Leveled Traits
      widget.initialLeveledTraits.forEach((groupName, traitIndex) {
        final List<SimpleTrait>? traitsInGroup =
            _dynamicTraitData['leveled'][groupName]?.cast<SimpleTrait>();
        if (traitsInGroup != null &&
            traitIndex >= 0 &&
            traitIndex < traitsInGroup.length) {
          _selectedLeveledTraits[groupName] = traitsInGroup[traitIndex].name;
        }
      });

      // Separate congenital and physical traits from the initial set
      final physicalTraitNames = _dynamicTraitData['physical']
          .cast<SimpleTrait>()
          .map((t) => t.name)
          .toSet();
      final congenitalTraitNames = _dynamicTraitData['congenital']
          .cast<SimpleTrait>()
          .map((t) => t.name)
          .toSet();

      for (final traitName in widget.initialSelectedTraits) {
        if (physicalTraitNames.contains(traitName)) {
          _selectedPhysicalTraits.add(traitName);
        }
        // We only want to keep the purely congenital traits in this set.
        if (!congenitalTraitNames.contains(traitName)) {
          // This handles cases where a physical trait might have been saved
          // under the 'congenital' key from the old combined logic.
          _selectedCongenitalTraits.remove(traitName);
        }
      }
    } catch (e) {
      debugPrint('Error initializing trait editor state: $e');
      // Handle error, maybe show a dialog or pop the screen
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadCustomTraits() {
    final customTraits = _traitService.loadCustomTraits();
    setState(() {
      (_dynamicTraitData['congenital'] as List).addAll(
        customTraits['congenital']!,
      );
      (_dynamicTraitData['physical'] as List).addAll(customTraits['physical']!);
    });
  }

  void _saveAndExit() {
    // When closing, you can return a map of all the selected traits

    // Convert leveled traits from Map<String, String> to Map<String, int> for saving
    final Map<String, int> leveledTraitsToSave = {};
    _selectedLeveledTraits.forEach((groupName, traitName) {
      final List<SimpleTrait> traitsInGroup =
          _dynamicTraitData['leveled'][groupName].cast<SimpleTrait>();
      final index = traitsInGroup.indexWhere((t) => t.name == traitName);
      if (index != -1) {
        leveledTraitsToSave[groupName] = index;
      }
    });

    // Combine congenital and physical traits for saving
    final Set<String> allCongenitalTraits = {}
      ..addAll(_selectedCongenitalTraits)
      ..addAll(_selectedPhysicalTraits);

    final results = {
      'personality': _selectedPersonalityTraits,
      'leveled': leveledTraitsToSave,
      'congenital': allCongenitalTraits,
    };
    Navigator.of(context).pop(results);
  }

  bool _categoryHasSearchResults(int tabIndex) {
    if (_searchQuery.isEmpty) return false;

    switch (tabIndex) {
      case 0: // Personality
        final List<PersonalityTrait> personalityTraits =
            _dynamicTraitData['personality'].cast<PersonalityTrait>();
        return personalityTraits.any((traitGroup) {
          if (traitGroup.groupName.toLowerCase().contains(_searchQuery)) {
            return true;
          }
          return traitGroup.options.any(
            (option) =>
                option.name.toLowerCase().contains(_searchQuery) ||
                option.explanation.toLowerCase().contains(_searchQuery),
          );
        });
      case 1: // Education
        return false; // No searchable content yet
      case 2: // Congenital
        final List<SimpleTrait> traits = _dynamicTraitData['congenital']
            .cast<SimpleTrait>();
        return traits.any(
          (trait) =>
              trait.name.toLowerCase().contains(_searchQuery) ||
              trait.explanation.toLowerCase().contains(_searchQuery),
        );
      case 3: // Leveled
        final Map<String, List<SimpleTrait>> allLeveledTraits =
            (_dynamicTraitData['leveled'] as Map).map(
              (key, value) => MapEntry(key, value.cast<SimpleTrait>()),
            );
        return allLeveledTraits.entries.any((entry) {
          if (entry.key.toLowerCase().contains(_searchQuery)) return true;
          return entry.value.any(
            (trait) =>
                trait.name.toLowerCase().contains(_searchQuery) ||
                trait.explanation.toLowerCase().contains(_searchQuery),
          );
        });
      case 4: // Physical
        final List<SimpleTrait> traits = _dynamicTraitData['physical']
            .cast<SimpleTrait>();
        return traits.any(
          (trait) =>
              trait.name.toLowerCase().contains(_searchQuery) ||
              trait.explanation.toLowerCase().contains(_searchQuery),
        );
      default:
        return false;
    }
  }

  Widget _buildTab(String text, int index) {
    final bool hasResults = _categoryHasSearchResults(index);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (hasResults) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 4,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search all traits...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    return TabBarView(
      controller: _tabController,
      children: [
        // 1. Personality Traits
        _buildTabContent(
          context,
          'Personality Traits',
          "Core dualities and spectrums that define a character's behavior.",
          const Color(0xFF3B82F6),
          (constraints) => _buildPersonalityTraits(colorScheme, constraints),
        ),
        // 2. Educational Traits
        _buildTabContent(
          context,
          'Educational Traits',
          'Skills and knowledge acquired through learning and experience.',
          const Color(0xFFF59E0B),
          (constraints) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Educational Traits section is reserved and currently blank.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        // 3. Congenital Traits
        _buildTabContent(
          context,
          'Congenital Traits',
          'Inborn traits that are part of a character from birth.',
          const Color(0xFF10B981),
          (constraints) =>
              _buildMultiSelectTraits('congenital', const Color(0xFF10B981)),
        ),
        // 4. Leveled Traits
        _buildTabContent(
          context,
          'Leveled Traits',
          'Attributes that exist on a spectrum, like appearance or intelligence.',
          const Color(0xFF9B34EB),
          (constraints) => _buildLeveledTraits(),
        ),
        // 5. Physical Traits
        _buildTabContent(
          context,
          'Physical Traits',
          'Acquired physical characteristics, scars, or conditions.',
          const Color(0xFFEF4444),
          (constraints) =>
              _buildMultiSelectTraits('physical', const Color(0xFFEF4444)),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'Character Trait Selection',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _saveAndExit, child: const Text('Done')),
        const SizedBox(width: 16),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          _buildTab('Personality', 0),
          _buildTab('Education', 1),
          _buildTab('Congenital', 2),
          _buildTab('Leveled', 3),
          _buildTab('Physical', 4),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    String title,
    String subtitle,
    Color accentColor,
    Widget Function(BoxConstraints) contentBuilder,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: const EdgeInsets.all(24.0), // This was correct
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  height: 4,
                  width: 100,
                  color: accentColor,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                contentBuilder(constraints),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildGlobalSearchHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCustomTraitDialog(String type) async {
    final newTrait = await showDialog<SimpleTrait>(
      context: context,
      builder: (context) => _CustomTraitDialog(type: type),
    );

    if (newTrait != null) {
      await _traitService.saveCustomTrait(newTrait);
      setState(() {
        // Add the new trait to our dynamic data source
        (_dynamicTraitData[type] as List<dynamic>).add(newTrait);
        // Automatically select the newly created trait
        if (type == 'congenital') {
          _selectedCongenitalTraits.add(newTrait.name);
        } else if (type == 'physical') {
          _selectedPhysicalTraits.add(newTrait.name);
        }
      });
    }
  }

  Future<void> _handleEditTrait(SimpleTrait traitToEdit, String type) async {
    final editedTrait = await showDialog<SimpleTrait>(
      context: context,
      builder: (context) =>
          _CustomTraitDialog(initialTrait: traitToEdit, type: type),
    );

    if (editedTrait != null) {
      // Persist the change using the service
      await _traitService.updateCustomTrait(traitToEdit, editedTrait);

      setState(() {
        final traitList = (_dynamicTraitData[type] as List);
        final index = traitList.indexWhere((t) => t.name == traitToEdit.name);
        if (index != -1) {
          traitList[index] = editedTrait;

          // If the name changed, update the selection sets
          final selectionSet = type == 'congenital'
              ? _selectedCongenitalTraits
              : _selectedPhysicalTraits;
          if (selectionSet.contains(traitToEdit.name)) {
            selectionSet.remove(traitToEdit.name);
            selectionSet.add(editedTrait.name);
          }
        }
      });
    }
  }

  Future<void> _handleDeleteTrait(
    SimpleTrait traitToDelete,
    String type,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => KeyboardAwareDialog(
        title: const Text('Delete Trait'),
        content: Text(
          'Are you sure you want to permanently delete the trait "${traitToDelete.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed == true) {
      await _traitService.deleteCustomTrait(traitToDelete);
      setState(() {
        (_dynamicTraitData[type] as List<dynamic>).removeWhere(
          (t) => t.name == traitToDelete.name,
        );
        if (type == 'congenital') {
          _selectedCongenitalTraits.remove(traitToDelete.name);
        } else if (type == 'physical') {
          _selectedPhysicalTraits.remove(traitToDelete.name);
        }
      });
    }
  }

  Widget _buildAddButton(String type) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(
            'Create Custom ${type.replaceFirst(type[0], type[0].toUpperCase())} Trait',
          ),
          onPressed: () => _showCreateCustomTraitDialog(type),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalityTraits(
    ColorScheme colorScheme,
    BoxConstraints constraints,
  ) {
    final List<PersonalityTrait> personalityTraits = traitData['personality']
        .cast<PersonalityTrait>();

    // Filter traits based on the search query
    final filteredTraits = personalityTraits.where((traitGroup) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      if (traitGroup.groupName.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      return traitGroup.options.any(
        (option) =>
            option.name.toLowerCase().contains(_searchQuery) ||
            option.explanation.toLowerCase().contains(_searchQuery),
      );
    }).toList();

    final dichotomousTraits = filteredTraits
        .where((t) => t.options.length == 2)
        .toList();
    final spectrumTraits = filteredTraits
        .where((t) => t.options.length > 2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Dualities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / 450).ceil().clamp(1, 2),
            mainAxisExtent: 200,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: dichotomousTraits.length,
          itemBuilder: (context, index) =>
              _buildDichotomousGroup(dichotomousTraits[index]),
        ),
        const SizedBox(height: 24),
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 24),
        Text(
          'Spectrums (Empathy, Courage, Reliability)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        ...spectrumTraits.map((t) => _buildSpectrumGroup(t)),
      ],
    );
  }

  // Handles the two-choice Dichotomous personality traits
  Widget _buildDichotomousGroup(PersonalityTrait traitGroup) {
    final List<TraitOption> options = traitGroup.options;
    final String groupName = traitGroup.groupName;
    final int? selectedValue = _selectedPersonalityTraits[groupName];
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Assert that there are exactly 2 options for dichotomous traits
    assert(
      options.length == 2,
      'Dichotomous traits must have exactly 2 options',
    );

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withAlpha(13),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: TextStyle(
              fontSize: 14, // This was correct
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Use Row with Expanded children instead of Wrap to prevent vertical wrapping and overflow
          Row(
            children: [
              Expanded(
                child: _buildDichotomousButton(
                  option: options[0],
                  isSelected: selectedValue == options[0].value,
                  onTap: () => setState(
                    () => _selectedPersonalityTraits[groupName] =
                        selectedValue == options[0].value
                        ? 0
                        : options[0].value,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildDichotomousButton(
                  option: options[1],
                  isSelected: selectedValue == options[1].value,
                  onTap: () => setState(
                    () => _selectedPersonalityTraits[groupName] =
                        selectedValue == options[1].value
                        ? 0
                        : options[1].value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDichotomousButton({
    required TraitOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color selectedColor = colorScheme.primary;
    final Color unselectedBg = colorScheme.secondaryContainer;
    final Color selectedIconContrast = colorScheme.primary.withAlpha(204);
    final Color unselectedIconBg = colorScheme.secondaryContainer;

    final Color buttonColor = isSelected ? selectedColor : unselectedBg;
    final Color iconAreaColor = isSelected
        ? selectedIconContrast
        : unselectedIconBg;
    final Color iconColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.primary;
    final Color titleColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final Color explanationColor = isSelected
        ? colorScheme.onPrimary.withAlpha(179)
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withAlpha(128),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Icon Area
              Container(
                width: 65,
                decoration: BoxDecoration(color: iconAreaColor),
                child: Center(
                  child: Text(
                    option.icon,
                    style: TextStyle(fontSize: 32, color: iconColor),
                  ),
                ),
              ),
              // Right Text Area
              Flexible(
                // Use Flexible instead of Expanded
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        // Wrap the explanation Text in Flexible to prevent any potential inner overflow
                        child: Text(
                          option.explanation,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                explanationColor, // This is now a non-const value
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handles the 3 or 4-choice Spectrum personality traits
  Widget _buildSpectrumGroup(PersonalityTrait traitGroup) {
    final List<TraitOption> options = traitGroup.options;
    final String groupName = traitGroup.groupName;
    final int? selectedValue = _selectedPersonalityTraits[groupName];
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Determine grid layout based on number of options
    final int crossAxisCount;
    if (options.length == 4) {
      crossAxisCount = 4;
    } else if (options.length == 3 || options.length > 6) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withAlpha(13),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 4.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$groupName Spectrum',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3.5, // Make buttons wider
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValue == option.value;
              return _buildSpectrumButton(
                option: option,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedPersonalityTraits[groupName] = isSelected
                        ? 0
                        : option.value;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // New button widget specifically for spectrum traits to match horizontal style
  Widget _buildSpectrumButton({
    required TraitOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color accentColor = colorScheme.primary;

    final Color selectedColor = accentColor;
    final Color unselectedBg = colorScheme.surfaceContainerHighest;
    final Color selectedIconContrast = accentColor.withAlpha(204);
    final Color unselectedIconBg = accentColor.withAlpha(26);

    final Color buttonColor = isSelected ? selectedColor : unselectedBg;
    final Color iconAreaColor = isSelected
        ? selectedIconContrast
        : unselectedIconBg;
    final Color iconColor = isSelected ? colorScheme.onPrimary : accentColor;
    final Color titleColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final Color explanationColor = isSelected
        ? colorScheme.onPrimary.withAlpha(179)
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withAlpha(128),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 50, // Smaller icon area
              decoration: BoxDecoration(color: iconAreaColor),
              child: Center(
                child: Text(
                  option.icon,
                  style: TextStyle(fontSize: 24, color: iconColor),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        option.explanation,
                        style: TextStyle(
                          fontSize: 11,
                          color: explanationColor,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeveledTraits() {
    const Color purpleAccent = Color(0xFF9B34EB);
    final Map<String, List<SimpleTrait>> allLeveledTraits =
        (traitData['leveled'] as Map).map(
          (key, value) => MapEntry(key, value.cast<SimpleTrait>()),
        );

    final filteredGroups = allLeveledTraits.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      if (entry.key.toLowerCase().contains(_searchQuery)) return true;
      return entry.value.any(
        (trait) =>
            trait.name.toLowerCase().contains(_searchQuery) ||
            trait.explanation.toLowerCase().contains(_searchQuery),
      );
    });

    if (filteredGroups.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsFound();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredGroups.map<Widget>((entry) {
        final groupName = entry.key;
        final List<SimpleTrait> traits = entry.value;
        final String? selectedName = _selectedLeveledTraits[groupName];

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$groupName Spectrum',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: purpleAccent,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio:
                      3.5, // Match aspect ratio of other horizontal buttons
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: traits.length,
                itemBuilder: (context, index) {
                  final trait = traits[index];
                  final isSelected = selectedName == trait.name;

                  return _buildHorizontalTraitButton(
                    name: trait.name,
                    icon: trait.icon,
                    explanation: trait.explanation,
                    isSelected: isSelected,
                    accentColor: purpleAccent,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedLeveledTraits.remove(groupName);
                        } else {
                          _selectedLeveledTraits[groupName] = trait.name;
                        }
                      });
                    },
                    isCustom: false, // Leveled traits are not custom
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectTraits(String type, Color accentColor) {
    final List<SimpleTrait> allTraits = _dynamicTraitData[type]
        .cast<SimpleTrait>();
    final Set<String> selectedNames = type == 'congenital'
        ? _selectedCongenitalTraits
        : _selectedPhysicalTraits;

    // Get the original default traits to distinguish them from custom ones
    final defaultTraitNames = (traitData[type] as List<dynamic>)
        .cast<SimpleTrait>()
        .map((t) => t.name)
        .toSet();

    final filteredTraits = allTraits.where((trait) {
      if (_searchQuery.isEmpty) return true;
      return trait.name.toLowerCase().contains(_searchQuery) ||
          trait.explanation.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredTraits.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsFound();
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent:
                400, // Max width of button for responsive layout
            mainAxisExtent: 110,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: filteredTraits.length,
          itemBuilder: (context, index) {
            final trait = filteredTraits[index];
            final isSelected = selectedNames.contains(trait.name);
            final isCustom = !defaultTraitNames.contains(trait.name);

            return _buildHorizontalTraitButton(
              name: trait.name,
              icon: trait.icon,
              explanation: trait.explanation,
              isSelected: isSelected,
              accentColor: accentColor,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedNames.remove(trait.name);
                  } else {
                    selectedNames.add(trait.name);
                  }
                });
              },
              isCustom: isCustom,
              onEdit: () => _handleEditTrait(trait, type),
              onDelete: () => _handleDeleteTrait(trait, type),
            );
          },
        ),
        _buildAddButton(type),
      ],
    );
  }

  Widget _buildNoResultsFound() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          'No traits found for "$_searchQuery"',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Handles Congenital, Physical, and Leveled traits (Icon-Left Style)
  Widget _buildHorizontalTraitButton({
    required String name,
    required String icon,
    required String explanation,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
    bool isCustom = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color selectedColor = colorScheme.primary;
    final Color unselectedBg = colorScheme.secondaryContainer;
    final Color selectedIconContrast = colorScheme.primary.withAlpha(204);
    final Color unselectedIconBg = accentColor.withAlpha(26);

    final Color buttonColor = isSelected ? selectedColor : unselectedBg;
    final Color iconAreaColor = isSelected
        ? selectedIconContrast
        : unselectedIconBg;
    final Color iconColor = isSelected ? colorScheme.onPrimary : accentColor;
    final Color titleColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final Color explanationColor = isSelected
        ? colorScheme.onPrimary.withAlpha(
            179,
          ) // Use withAlpha for better precision
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withAlpha(128),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Icon Area (w-1/4)
                Container(
                  width: 80, // Use a fixed width for the icon area
                  decoration: BoxDecoration(color: iconAreaColor),
                  child: Center(
                    child: Text(
                      icon,
                      style: TextStyle(fontSize: 32, color: iconColor),
                    ),
                  ),
                ),
                // Right Text Area (expanded)
                SizedBox(
                  width: 250, // Give a reasonable width to the text area
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          // Wrap the explanation Text in Flexible to prevent any potential inner overflow
                          child: Text(
                            explanation,
                            style: TextStyle(
                              // Removed const
                              fontSize: 12,
                              color: explanationColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isCustom)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert, color: titleColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomTraitDialog extends StatefulWidget {
  final SimpleTrait? initialTrait;
  final String type; // 'congenital' or 'physical'
  const _CustomTraitDialog({this.initialTrait, required this.type});

  @override
  State<_CustomTraitDialog> createState() => _CustomTraitDialogState();
}

class _CustomTraitDialogState extends State<_CustomTraitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _explanationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTrait != null) {
      _nameController.text = widget.initialTrait!.name;
      _iconController.text = widget.initialTrait!.icon;
      _explanationController.text = widget.initialTrait!.explanation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newTrait = SimpleTrait(
        name: _nameController.text.trim(),
        icon: _iconController.text.trim(),
        explanation: _explanationController.text.trim(),
        type: widget.type,
      );
      Navigator.of(context).pop(newTrait);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTrait != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Custom Trait' : 'Create Custom Trait'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Trait Name'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: 'Icon (Emoji)'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Icon cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(labelText: 'Explanation'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Explanation cannot be empty'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
