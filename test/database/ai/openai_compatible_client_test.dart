import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lore_keeper/database/ai/device_ai/openai_compatible_client.dart';

void main() {
  OpenAiCompatibleClient clientWith(MockClient mock) => OpenAiCompatibleClient(
    baseUrl: 'http://127.0.0.1:1234/v1',
    client: mock,
    timeout: const Duration(seconds: 2),
  );

  group('OpenAiCompatibleClient.listModels', () {
    test('parses the OpenAI model catalog', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/models');
          return http.Response(
            jsonEncode({
              'object': 'list',
              'data': [
                {'id': 'phi-silica', 'object': 'model'},
                {'id': 'qwen2.5-7b-instruct', 'object': 'model'},
              ],
            }),
            200,
          );
        }),
      );

      final models = await client.listModels();
      expect(models, isNotNull);
      expect(models!.map((m) => m.id), ['phi-silica', 'qwen2.5-7b-instruct']);
    });

    test('returns null on non-200', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('boom', 500)),
      );
      expect(await client.listModels(), isNull);
    });

    test('returns null when body is not a catalog', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      expect(await client.listModels(), isNull);
    });
  });

  group('OpenAiCompatibleClient.chat', () {
    test('parses assistant reply and usage', () async {
      late Map<String, dynamic> sentBody;
      final client = clientWith(
        MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Hello!'},
                },
              ],
              'usage': {'prompt_tokens': 12, 'completion_tokens': 3},
            }),
            200,
          );
        }),
      );

      final result = await client.chat(
        model: 'phi-silica',
        messages: const [OpenAiChatMessage('user', 'Hi')],
        temperature: 0.7,
      );

      expect(result, isNotNull);
      expect(result!.text, 'Hello!');
      expect(result.promptTokens, 12);
      expect(result.completionTokens, 3);
      expect(sentBody['model'], 'phi-silica');
      expect(sentBody['stream'], isFalse);
      expect(sentBody['temperature'], 0.7);
      expect(sentBody['messages'], [
        {'role': 'user', 'content': 'Hi'},
      ]);
    });

    test('returns null on failure', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('nope', 404)),
      );
      final result = await client.chat(
        model: 'phi-silica',
        messages: const [OpenAiChatMessage('user', 'Hi')],
      );
      expect(result, isNull);
    });
  });

  group('OpenAiCompatibleClient.chatStream', () {
    test('yields SSE content deltas until [DONE]', () async {
      final client = clientWith(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['stream'], isTrue);
          return http.Response(
            'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n'
            'data: {"choices":[{"delta":{"content":" world"}}]}\n\n'
            'data: [DONE]\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      final chunks = await client
          .chatStream(
            model: 'phi-silica',
            messages: const [OpenAiChatMessage('user', 'Hi')],
          )
          .toList();
      expect(chunks, ['Hello', ' world']);
    });

    test('ignores non-data lines and empty deltas', () async {
      final client = clientWith(
        MockClient(
          (request) async => http.Response(
            ': keep-alive\n\n'
            'event: ping\n\n'
            'data: {"choices":[{"delta":{}}]}\n\n'
            'data: {"choices":[{"delta":{"content":"only"}}]}\n\n'
            'data: [DONE]\n\n',
            200,
          ),
        ),
      );
      expect(await client.chatStream(model: 'm', messages: const []).toList(), [
        'only',
      ]);
    });
  });

  group('OpenAiCompatibleClient.embed', () {
    test('parses embedding vector', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(request.url.path, '/v1/embeddings');
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
        }),
      );
      expect(await client.embed('phi-embed', 'text'), [0.1, 0.2, 0.3]);
    });

    test('returns null when embeddings are unsupported', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('not found', 404)),
      );
      expect(await client.embed('chat-only', 'text'), isNull);
    });
  });
}
