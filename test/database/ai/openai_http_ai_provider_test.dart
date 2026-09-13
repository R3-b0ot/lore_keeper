import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/ai/ai_provider_factory.dart';
import 'package:lore_keeper/database/ai/llamadart/llama_cpp_ai_provider.dart';
import 'package:lore_keeper/database/ai/openai_http_ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';

void main() {
  MockClient answering({
    List<String> modelIds = const ['phi-silica', 'qwen2.5-7b-instruct'],
    bool embedSupported = true,
  }) {
    return MockClient((request) async {
      switch (request.url.path) {
        case '/v1/models':
          return http.Response(
            jsonEncode({
              'object': 'list',
              'data': [
                for (final id in modelIds) {'id': id},
              ],
            }),
            200,
          );
        case '/v1/embeddings':
          if (!embedSupported) return http.Response('unsupported', 404);
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'embedding': [0.1, 0.2, 0.3],
                },
              ],
            }),
            200,
          );
        case '/v1/chat/completions':
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content':
                        'A six-legged feline native to the volcanic '
                        'badlands of Kharos.',
                  },
                },
              ],
            }),
            200,
          );
        default:
          return http.Response('{}', 200);
      }
    });
  }

  group('OpenAiHttpAiProvider', () {
    test('load() resolves the configured model', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'qwen2.5-7b-instruct',
        client: answering(),
      );

      expect(provider.isReady, isFalse);
      expect(await provider.load(), isTrue);
      expect(provider.isReady, isTrue);
      expect(provider.modelId, 'qwen2.5-7b-instruct');
    });

    test('load() falls back to the first model when id is unknown', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'missing-model',
        client: answering(),
      );
      expect(await provider.load(), isTrue);
      expect(provider.modelId, 'phi-silica');
    });

    test('load() fails when no model is listed', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        client: MockClient((request) async => http.Response('{}', 200)),
      );
      expect(await provider.load(), isFalse);
      expect(provider.isReady, isFalse);
    });

    test('embed() returns null before load', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        client: answering(),
      );
      expect(await provider.embed('hello'), isNull);
    });

    test('embed() returns the vector when ready', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'phi-silica',
        client: answering(),
      );
      await provider.load();
      expect(await provider.embed('hello'), [0.1, 0.2, 0.3]);
    });

    test('embed() returns null when the engine cannot embed', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'phi-silica',
        client: answering(embedSupported: false),
      );
      await provider.load();
      expect(await provider.embed('hello'), isNull);
    });

    test('unload() clears ready state', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        client: answering(),
      );
      await provider.load();
      await provider.unload();
      expect(provider.isReady, isFalse);
      expect(provider.modelId, isEmpty);
    });

    test('chat() returns null before load', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        client: answering(),
      );
      expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
    });

    test('chat() returns the model reply when ready', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'phi-silica',
        client: answering(),
      );
      await provider.load();
      expect(
        await provider.chat(
          systemPrompt: 'You are a worldbuilding assistant.',
          userPrompt: 'Describe a Moonfire Lynx.',
        ),
        'A six-legged feline native to the volcanic badlands of Kharos.',
      );
    });

    test('chat() returns null when the engine fails', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'phi-silica',
        client: MockClient(
          (request) async => http.Response('unavailable', 500),
        ),
      );
      await provider.load();
      expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
    });

    test('chat() returns null for an empty assistant reply', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        modelId: 'phi-silica',
        client: MockClient((request) async {
          if (request.url.path == '/v1/models') {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 'phi-silica'},
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '   '},
                },
              ],
            }),
            200,
          );
        }),
      );
      await provider.load();
      expect(await provider.chat(systemPrompt: 's', userPrompt: 'u'), isNull);
    });

    test('suggestRelated() stays null (nothing to rank against)', () async {
      final provider = OpenAiHttpAiProvider(
        baseUrl: 'http://localhost:1234/v1',
        client: answering(),
      );
      const ref = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      expect(await provider.suggestRelated(ref), isNull);
    });
  });

  group('buildAiProviderFromSettings', () {
    test('returns NullAiProvider when AI is disabled', () {
      expect(
        buildAiProviderFromSettings(
          enabled: false,
          provider: AiProviders.deviceFoundry,
          endpoint: 'http://localhost:1234/v1',
          model: 'phi-silica',
        ),
        isA<NullAiProvider>(),
      );
    });

    test('returns NullAiProvider for unsupported providers', () {
      expect(
        buildAiProviderFromSettings(
          enabled: true,
          provider: AiProviders.anthropic,
          endpoint: 'http://localhost:1234/v1',
          model: 'm',
        ),
        isA<NullAiProvider>(),
      );
    });

    test('returns NullAiProvider when the endpoint is empty', () {
      expect(
        buildAiProviderFromSettings(
          enabled: true,
          provider: AiProviders.local,
          endpoint: '   ',
          model: 'm',
        ),
        isA<NullAiProvider>(),
      );
    });

    test('builds an HTTP provider for device AI', () {
      final provider = buildAiProviderFromSettings(
        enabled: true,
        provider: AiProviders.deviceFoundry,
        endpoint: 'http://localhost:5273/v1',
        model: 'phi-silica',
      );
      expect(provider, isA<OpenAiHttpAiProvider>());
    });

    test('builds the bundled on-device provider', () {
      final provider = buildAiProviderFromSettings(
        enabled: true,
        provider: AiProviders.onDevice,
        endpoint: '',
        model: '',
      );
      expect(provider, isA<LlamaCppAiProvider>());
    });

    test('returns NullAiProvider for bundled AI when disabled', () {
      expect(
        buildAiProviderFromSettings(
          enabled: false,
          provider: AiProviders.onDevice,
          endpoint: '',
          model: '',
        ),
        isA<NullAiProvider>(),
      );
    });
  });
}
