import 'package:flutter/material.dart';

// --- 1. Data Models ---

// Model for simple traits (Congenital, Physical)
class SimpleTrait {
  final String name;
  final String icon;
  final String explanation;

  SimpleTrait({
    required this.name,
    required this.icon,
    required this.explanation,
  });
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

class _TraitEditorScreenState extends State<TraitEditorScreen> {
  // State for selected traits
  late Set<String> _selectedCongenitalTraits;
  late Map<String, int> _selectedPersonalityTraits;
  late Map<String, String> _selectedLeveledTraits;
  late Set<String> _selectedPhysicalTraits;

  @override
  void initState() {
    super.initState();
    _selectedCongenitalTraits = Set.from(widget.initialSelectedTraits);
    _selectedPhysicalTraits = {}; // Will be populated from congenital traits
    _selectedLeveledTraits = {};
    _selectedPersonalityTraits = Map.from(widget.initialPersonalityTraits);

    // Initialize Leveled Traits
    widget.initialLeveledTraits.forEach((groupName, traitIndex) {
      final List<SimpleTrait>? traitsInGroup = traitData['leveled'][groupName]
          ?.cast<SimpleTrait>();
      if (traitsInGroup != null &&
          traitIndex >= 0 &&
          traitIndex < traitsInGroup.length) {
        _selectedLeveledTraits[groupName] = traitsInGroup[traitIndex].name;
      }
    });

    // Separate congenital and physical traits from the initial set
    final physicalTraitNames = traitData['physical']
        .cast<SimpleTrait>()
        .map((t) => t.name)
        .toSet();
    final congenitalTraitNames = traitData['congenital']
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
  }

  @override
  void dispose() {
    // Dispose any controllers if they were used
    super.dispose();
  }

  void _saveAndExit() {
    // When closing, you can return a map of all the selected traits

    // Convert leveled traits from Map<String, String> to Map<String, int> for saving
    final Map<String, int> leveledTraitsToSave = {};
    _selectedLeveledTraits.forEach((groupName, traitName) {
      final List<SimpleTrait> traitsInGroup = traitData['leveled'][groupName]
          .cast<SimpleTrait>();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _saveAndExit, child: const Text('Done')),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Character Trait Selection',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                height: 4,
                width: 100,
                color: colorScheme.primary,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
              ),
              Text(
                "Select traits to define the character's core attributes and history.",
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Personality Traits
              _buildSection(
                title: 'Personality Traits',
                accentColor: const Color(0xFF3B82F6), // blue-500
                content: _buildPersonalityTraits(colorScheme),
              ),

              // 2. Educational Traits (Placeholder)
              _buildSection(
                title: 'Educational Traits',
                accentColor: const Color(0xFFF59E0B), // amber-500 (yellow)
                content: Padding(
                  padding: const EdgeInsets.all(16.0),
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

              // 3. Congenital or Inherited Traits
              _buildSection(
                title: 'Congenital or Inherited Traits',
                accentColor: const Color(0xFF10B981), // green-500
                content: _buildMultiSelectTraits(
                  'congenital',
                  const Color(0xFF10B981),
                ),
              ),

              // 4. Leveled Congenital Traits (Spectrum)
              _buildSection(
                title: 'Leveled Congenital Traits (Spectrum)',
                accentColor: const Color(0xFF9B34EB), // purple-500
                content: _buildLeveledTraits(),
              ),

              // 5. Physical Traits
              _buildSection(
                title: 'Physical Traits',
                accentColor: const Color(0xFFEF4444), // red-500
                content: _buildMultiSelectTraits(
                  'physical',
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Renders the main content card for each section
  Widget _buildSection({
    required String title,
    required Color accentColor,
    required Widget content,
    String? subtitle,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 32.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(top: BorderSide(color: accentColor, width: 4.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, // This was correct
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant, // This was correct
                ),
              ),
            ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildPersonalityTraits(ColorScheme colorScheme) {
    final List<PersonalityTrait> personalityTraits = traitData['personality']
        .cast<PersonalityTrait>();
    final dichotomousTraits = personalityTraits
        .where((t) => t.options.length == 2)
        .toList();
    final spectrumTraits = personalityTraits
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
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            childAspectRatio: 3.0,
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

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(204),
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
          Row(
            children: options.map((option) {
              final isSelected = selectedValue == option.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == options.first ? 8.0 : 0.0,
                    left: option == options.last ? 8.0 : 0.0,
                  ),
                  child: _buildDichotomousButton(
                    option: option,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPersonalityTraits.remove(groupName);
                        } else {
                          _selectedPersonalityTraits[groupName] = option.value;
                        }
                      });
                    },
                  ),
                ),
              );
            }).toList(),
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
    final Color unselectedBg = colorScheme.surface;
    final Color selectedIconContrast = colorScheme.primary.withAlpha(204);
    final Color unselectedIconBg = colorScheme.secondaryContainer;

    final Color buttonColor = isSelected ? selectedColor : unselectedBg;
    final Color iconAreaColor = isSelected
        ? selectedIconContrast
        : unselectedIconBg;
    final Color iconColor = isSelected ? Colors.white : colorScheme.primary;
    final Color titleColor = isSelected ? Colors.white : colorScheme.onSurface;
    final Color explanationColor = isSelected
        ? Colors.white70
        : colorScheme.onSurfaceVariant; // This was correct

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : colorScheme.outlineVariant.withAlpha(128),
            width: 1.0,
          ),
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
            Expanded(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.explanation,
                      style: TextStyle(
                        fontSize: 10,
                        color: explanationColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  // Handles the 3 or 4-choice Spectrum personality traits
  Widget _buildSpectrumGroup(PersonalityTrait traitGroup) {
    final List<TraitOption> options = traitGroup.options;
    final String groupName = traitGroup.groupName;
    final int? selectedValue = _selectedPersonalityTraits[groupName];
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final crossAxisCount = options.length == 4 ? 2 : 3;

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
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dynamic crossAxisCount based on constraint width
              int dynamicCrossAxisCount = (constraints.maxWidth / 200)
                  .floor()
                  .clamp(1, crossAxisCount);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: dynamicCrossAxisCount,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedValue == option.value;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPersonalityTraits.remove(groupName);
                        } else {
                          _selectedPersonalityTraits[groupName] = option.value;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? colorScheme.primary.withAlpha(102)
                                : Colors.transparent,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.explanation,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white70
                                  : colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeveledTraits() {
    const Color purpleAccent = Color(0xFF9B34EB); // purple-500

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: traitData['leveled'].keys.map<Widget>((groupName) {
        final List<SimpleTrait> traits = traitData['leveled'][groupName]
            .cast<SimpleTrait>();
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
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450,
                  mainAxisExtent: 110, // Set a fixed height for the row
                  crossAxisSpacing: 8.0, // Keep horizontal spacing
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
    final List<SimpleTrait> traits = traitData[type].cast<SimpleTrait>();
    final Set<String> selectedNames = type == 'congenital'
        ? _selectedCongenitalTraits
        : _selectedPhysicalTraits;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, // Max width of button for responsive layout
        mainAxisExtent: 110, // Set a fixed height for the row
        crossAxisSpacing: 12.0, // Keep horizontal spacing
        mainAxisSpacing: 12.0,
      ),
      itemCount: traits.length,
      itemBuilder: (context, index) {
        final trait = traits[index];
        final isSelected = selectedNames.contains(trait.name);

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
        );
      },
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
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color selectedColor = colorScheme.primary;
    final Color selectedIconContrast = colorScheme.primary.withAlpha(204);
    final Color unselectedIconBg = accentColor.withAlpha(26);

    final Color buttonColor = isSelected ? selectedColor : colorScheme.surface;
    final Color iconAreaColor = isSelected
        ? selectedIconContrast
        : unselectedIconBg;
    final Color iconColor = isSelected ? Colors.white : accentColor;
    final Color titleColor = isSelected ? Colors.white : colorScheme.onSurface;
    final Color explanationColor = isSelected
        ? Colors.white70
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : colorScheme.outlineVariant.withAlpha(128),
            width: 1.0,
          ),
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
            // Left Icon Area (w-1/4)
            Container(
              width: 100, // Fixed width for consistent look on large screens
              decoration: BoxDecoration(color: iconAreaColor),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(fontSize: 32, color: iconColor),
                ),
              ),
            ),
            // Right Text Area (w-3/4)
            Expanded(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: explanationColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
