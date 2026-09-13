import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lore_keeper/database/ai/llamadart/llama_cpp_ai_provider.dart';
import 'package:lore_keeper/database/ai/species_ai/ai_species_service.dart';

/// Live diagnostic: exercises the real bundled on-device provider + real
/// species generation. Skipped unless LIVE_AI=1 so the normal suite never
/// downloads a model or touches native code.
void main() {
  final live = Platform.environment['LIVE_AI'] == '1';
  if (!live) {
    test('live diagnosis disabled (set LIVE_AI=1)', () {});
    return;
  }

  test('live bundled AI generation', () async {
    final runtime = LlamaDartRuntime();
    try {
      await runtime.loadModelSource(bundledModelSource);
      // ignore: avoid_print
      print('RUNTIME LOAD: ok');
    } catch (e, st) {
      // ignore: avoid_print
      print('RUNTIME LOAD FAILED: $e\n$st');
      fail('runtime load failed');
    }

    final raw = await runtime.chat(
      systemPrompt: AiSpeciesService.systemPrompt,
      userPrompt: 'Common name: Moonfire Lynx\n'
          'Description: A six-legged feline native to the volcanic badlands '
          'of Kharos, whose fur glows faintly.\n',
      temperature: 0.7,
      maxTokens: 1000,
    );
    // ignore: avoid_print
    print('RAW CHAT OUTPUT (${raw.length} chars):\n$raw');
    await runtime.unloadModel();

    final draft = AiSpeciesService().parse(raw, commonName: 'Moonfire Lynx');
    // ignore: avoid_print
    print(
      'PARSED: ${draft == null ? "NULL" : draft.path.map((s) => "${s.rank}:${s.name}").join(" > ")} | sci=${draft?.scientificName}',
    );
    expect(draft, isNotNull);
  });
}