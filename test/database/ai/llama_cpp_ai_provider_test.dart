import 'package:flutter_test/flutter_test.dart';

import 'package:lore_keeper/database/ai/llamadart/llama_cpp_ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';

/// Fake on-device runtime — no native code, no network.
class FakeDeviceLlamaRuntime implements DeviceLlamaRuntime {
  List<String> loadedSources = [];
  bool unloaded = false;
  bool throwOnLoad = false;
  bool throwOnEmbed = false;
  bool throwOnChat = false;
  List<double> embedding = [0.1, 0.2, 0.3];
  String chatReply = 'A six-legged feline native to the volcanic badlands.';

  @override
  Future<void> loadModelSource(String modelSource) async {
    if (throwOnLoad) throw StateError('download failed');
    loadedSources.add(modelSource);
  }

  @override
  Future<List<double>> embed(String text, {bool normalize = true}) async {
    if (throwOnEmbed) throw StateError('embed failed');
    return embedding;
  }

  @override
  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (throwOnChat) throw StateError('chat failed');
    return chatReply;
  }

  @override
  Future<void> unloadModel() async {
    unloaded = true;
  }
}

void main() {
  late FakeDeviceLlamaRuntime runtime;
  late LlamaCppAiProvider provider;

  setUp(() {
    runtime = FakeDeviceLlamaRuntime();
    provider = LlamaCppAiProvider(runtime: runtime);
  });

  test('starts unloaded and not ready', () {
    expect(provider.isReady, isFalse);
    expect(provider.modelId, isEmpty);
  });

  test('load() downloads the default model and becomes ready', () async {
    final ok = await provider.load();
    expect(ok, isTrue);
    expect(provider.isReady, isTrue);
    expect(provider.modelId, bundledModelId);
    expect(runtime.loadedSources, [bundledModelSource]);
  });

  test('load() uses a custom model source when provided', () async {
    final custom = LlamaCppAiProvider(
      runtime: runtime,
      modelSource: 'hf://owner/repo/model.gguf',
    );
    await custom.load();
    expect(runtime.loadedSources, ['hf://owner/repo/model.gguf']);
  });

  test('load() fails gracefully when the download fails', () async {
    runtime.throwOnLoad = true;
    final ok = await provider.load();
    expect(ok, isFalse);
    expect(provider.isReady, isFalse);
  });

  test('embed() returns null before load', () async {
    expect(await provider.embed('hello'), isNull);
  });

  test('embed() returns the model vector when ready', () async {
    await provider.load();
    expect(await provider.embed('hello'), [0.1, 0.2, 0.3]);
  });

  test('embed() returns null when inference throws', () async {
    runtime.throwOnEmbed = true;
    await provider.load();
    expect(await provider.embed('hello'), isNull);
  });

  test('chat() returns null before load', () async {
    expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
  });

  test('chat() returns the model reply when ready', () async {
    runtime.chatReply = 'A glowing six-legged feline.';
    await provider.load();
    expect(
      await provider.chat(systemPrompt: 's', userPrompt: 'u'),
      'A glowing six-legged feline.',
    );
  });

  test('chat() returns null when inference throws', () async {
    runtime.throwOnChat = true;
    await provider.load();
    expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
  });

  test('chat() returns null for a whitespace-only reply', () async {
    runtime.chatReply = '   \n  ';
    await provider.load();
    expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
  });

  test('unload() releases the model and clears ready state', () async {
    await provider.load();
    await provider.unload();
    expect(provider.isReady, isFalse);
    expect(provider.modelId, isEmpty);
    expect(runtime.unloaded, isTrue);
  });

  test('unload() releases the model even when the runtime fails', () async {
    await provider.load();
    final failing = LlamaCppAiProvider(
      runtime: FakeDeviceLlamaRuntime()..throwOnLoad = true,
    );
    await failing.unload();
    expect(failing.isReady, isFalse);
  });

  test('suggestRelated() stays null (nothing to rank against)', () async {
    const ref = EntityRef(id: '1', entityType: 'X', projectId: 'P');
    expect(await provider.suggestRelated(ref), isNull);
  });

  test('serverless provider reports its display name', () {
    expect(provider.name, contains('llama.cpp'));
    expect(provider.modelVersion, 'unknown');
  });
}
