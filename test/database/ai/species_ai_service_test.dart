import 'package:flutter_test/flutter_test.dart';

import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/ai/species_ai/ai_species_service.dart';
import 'package:lore_keeper/database/entity_ref.dart';

/// In-memory [AiProvider] that never touches native code or the network.
class FakeAiProvider implements AiProvider {
  bool loadResult;
  String chatReply;
  bool throwOnLoad;
  bool throwOnChat;

  String? capturedSystem;
  String? capturedUser;
  double? capturedTemperature;
  int? capturedMaxTokens;

  FakeAiProvider({
    this.loadResult = true,
    this.chatReply = '',
    this.throwOnLoad = false,
    this.throwOnChat = false,
  });

  @override
  String get name => 'fake';

  @override
  String get modelId => 'fake-model';

  @override
  String get modelVersion => '1.0';

  @override
  bool get isReady => true;

  @override
  Future<bool> load() async {
    if (throwOnLoad) return false;
    return loadResult;
  }

  @override
  Future<void> unload() async {}

  @override
  Future<List<double>?> embed(String text) async => null;

  @override
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    capturedSystem = systemPrompt;
    capturedUser = userPrompt;
    capturedTemperature = temperature;
    capturedMaxTokens = maxTokens;
    if (throwOnChat) return null;
    return chatReply;
  }

  @override
  Future<List<AiSuggestion>?> suggestRelated(EntityRef entityRef) async => null;
}

const _validJson = '''
{
  "path": [
    {"rank": "category", "name": "Fauna"},
    {"rank": "kingdom", "name": "Animalia"},
    {"rank": "phylum", "name": "Chordata"},
    {"rank": "class", "name": "Mammalia"},
    {"rank": "order", "name": "Carnivora"},
    {"rank": "family", "name": "Felidae"},
    {"rank": "genus", "name": "Panthera"},
    {"rank": "species", "name": "Nyctalops Silva-Rians"}
  ],
  "scientificName": "Panthera Nyctalops",
  "status": "endangered",
  "origin": "Kharos",
  "averageLifespan": "25-30 years",
  "averageHeight": "90-110 cm",
  "reproduction": "Live birth, 61-day gestation",
  "diet": "Carnivorous",
  "sentience": "Sapient",
  "population": "~2 Million",
  "physiology": "Four eyes and a cold-adaptable coat.",
  "content": "The creature stalks the volcanic badlands at night."
}
''';

void main() {
  final service = AiSpeciesService();

  group('AiSpeciesService.parse', () {
    test('parses a complete valid reply', () {
      final draft = service.parse(_validJson, commonName: 'Shimmer Lynx')!;

      expect(draft.path.map((s) => '${s.rank}:${s.name}').toList(), [
        'category:Fauna',
        'kingdom:Animalia',
        'phylum:Chordata',
        'classRank:Mammalia',
        'order:Carnivora',
        'family:Felidae',
        'genus:Panthera',
        'species:Shimmer Lynx',
      ]);
      expect(draft.scientificName, 'Panthera Nyctalops');
      expect(draft.status, 'Endangered');
      expect(draft.origin, 'Kharos');
      expect(draft.averageLifespan, '25-30 years');
      expect(draft.averageHeight, '90-110 cm');
      expect(draft.reproduction, contains('61-day gestation'));
      expect(draft.diet, 'Carnivorous');
      expect(draft.sentience, 'Sapient');
      expect(draft.population, '~2 Million');
      expect(draft.physiology, contains('cold-adaptable'));
      expect(draft.content, contains('volcanic badlands'));
    });

    test('forces the species step to the user common name', () {
      final draft = service.parse(_validJson, commonName: 'Shimmer Lynx')!;
      final species = draft.path.singleWhere((s) => s.rank == 'species');
      expect(species.name, 'Shimmer Lynx');
    });

    test('extracts JSON wrapped in a markdown fence', () {
      final draft = service.parse(
        '```json\n$_validJson\n```',
        commonName: 'Shimmer Lynx',
      )!;
      expect(draft.scientificName, 'Panthera Nyctalops');
    });

    test('rejects replies without JSON', () {
      expect(service.parse('no json here', commonName: 'x'), isNull);
    });

    test('rejects malformed JSON', () {
      expect(service.parse('{nope', commonName: 'x'), isNull);
    });

    test('normalises category to Fauna when missing or invalid', () {
      final reply = _validJson.replaceFirst(
        '"category", "name": "Fauna"',
        '"category", "name": "Glowing Beasts"',
      );
      final draft = service.parse(reply, commonName: 'x')!;
      expect(draft.path.first.rank, 'category');
      expect(draft.path.first.name, 'Fauna');
    });

    test('adds a species step when the AI omits it', () {
      final reply = _validJson.replaceFirst(
        ',\n    {"rank": "species", "name": "Nyctalops Silva-Rians"}',
        '',
      );
      final draft = service.parse(reply, commonName: 'Moonfire Lynx')!;
      expect(draft.path.last.rank, 'species');
      expect(draft.path.last.name, 'Moonfire Lynx');
    });

    test('reorders a scrambling of ranks canonically', () {
      final reply = _validJson.replaceFirst(
        '''
  "path": [
    {"rank": "category", "name": "Fauna"},
    {"rank": "kingdom", "name": "Animalia"},''',
        '''
  "path": [
    {"rank": "genus", "name": "Panthera"},
    {"rank": "category", "name": "Fauna"},
    {"rank": "kingdom", "name": "Animalia"},
    {"rank": "genus", "name": "DuplicateGenus"},''',
      );
      final draft = service.parse(reply, commonName: 'x')!;
      final ranks = draft.path.map((s) => s.rank).toList();
      expect(ranks, [
        'category',
        'kingdom',
        'phylum',
        'classRank',
        'order',
        'family',
        'genus',
        'species',
      ]);
      expect(draft.path.firstWhere((s) => s.rank == 'genus').name, 'Panthera');
    });

    test('maps an unknown or missing status to Extant', () {
      final reply = _validJson.replaceFirst('"endangered"', '"missing"');
      final draft = service.parse(reply, commonName: 'x')!;
      expect(draft.status, 'Extant');
    });

    test('accepts all canonical statuses', () {
      for (final status in [
        'Extant',
        'Extinct',
        'Endangered',
        'Mythical',
        'Unknown',
      ]) {
        final reply = _validJson.replaceFirst('"endangered"', '"$status"');
        final draft = service.parse(reply, commonName: 'x')!;
        expect(draft.status, status);
      }
    });
  });

  group('AiSpeciesService.generate', () {
    test('returns null when the provider cannot load', () async {
      final provider = FakeAiProvider(throwOnLoad: true);
      final draft = await service.generate(
        provider: provider,
        commonName: 'Shimmer Lynx',
        description: 'A glowing lynx.',
      );
      expect(draft, isNull);
    });

    test('returns null when the provider has no reply', () async {
      final provider = FakeAiProvider(chatReply: '');
      final draft = await service.generate(
        provider: provider,
        commonName: 'Shimmer Lynx',
        description: 'A glowing lynx.',
      );
      expect(draft, isNull);
    });

    test('returns null when the reply is not JSON', () async {
      final provider = FakeAiProvider(chatReply: 'I cannot do that.');
      final draft = await service.generate(
        provider: provider,
        commonName: 'Shimmer Lynx',
        description: 'A glowing lynx.',
      );
      expect(draft, isNull);
    });

    test('parses a provider reply into an AiGeneratedSpecies', () async {
      final provider = FakeAiProvider(chatReply: _validJson);
      final draft = await service.generate(
        provider: provider,
        commonName: 'Shimmer Lynx',
        description: 'A six-legged lynx that glows.',
      );
      expect(draft, isNotNull);
      expect(draft!.scientificName, 'Panthera Nyctalops');
      expect(draft.status, 'Endangered');
      expect(provider.capturedSystem, contains('worldbuilding assistant'));
      expect(provider.capturedUser, contains('Shimmer Lynx'));
      expect(provider.capturedTemperature, 0.7);
      expect(provider.capturedMaxTokens, 1500);
    });

    test('forwards an explicit token budget', () async {
      final provider = FakeAiProvider(chatReply: _validJson);
      await service.generate(
        provider: provider,
        commonName: 'Shimmer Lynx',
        description: 'A glowing lynx.',
        maxTokens: 512,
      );
      expect(provider.capturedMaxTokens, 512);
    });
  });
}
