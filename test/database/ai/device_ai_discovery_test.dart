import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lore_keeper/database/ai/device_ai/device_ai_discovery.dart';

void main() {
  group('DeviceAiDiscovery', () {
    // The MockClient answers for every probed port; only 1234 returns a model
    // catalog, so discovery resolves to exactly one endpoint regardless of any
    // host listeners surfaced by the netstat scan.
    final discovery = DeviceAiDiscovery(
      probeTimeout: const Duration(milliseconds: 150),
      client: MockClient((request) async {
        if (request.url.port != 1234) return http.Response('{}', 200);
        if (request.url.path == '/v1/models') {
          return http.Response(
            jsonEncode({
              'object': 'list',
              'data': [
                {'id': 'phi-silica'},
                {'id': 'qwen2.5-7b-instruct'},
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );

    test('finds an OpenAI-compatible endpoint on a known port', () async {
      final endpoints = await discovery.discover();

      final lmStudio = endpoints.where(
        (e) => e.baseUrl == 'http://127.0.0.1:1234/v1',
      );
      expect(lmStudio, hasLength(1));
      expect(lmStudio.single.modelIds, ['phi-silica', 'qwen2.5-7b-instruct']);
    });

    test('labels the LM Studio port with its provider hint', () async {
      final endpoints = await discovery.discover();
      final lmStudio = endpoints.firstWhere(
        (e) => e.baseUrl == 'http://127.0.0.1:1234/v1',
      );
      expect(lmStudio.providerHint, contains('LM Studio'));
    });

    test('skips ports that are not known listeners', () async {
      final discovery = DeviceAiDiscovery(
        probeTimeout: const Duration(milliseconds: 150),
        client: MockClient(
          (request) async => request.url.port == 99999
              ? http.Response(
                  jsonEncode({
                    'object': 'list',
                    'data': [
                      {'id': 'x'},
                    ],
                  }),
                  200,
                )
              : http.Response('{}', 200),
        ),
      );
      // 99999 answers like a real engine, but it is not in the probe set, so
      // the scan never touches it.
      expect(await discovery.discover(), isEmpty);
    });
  });

  group('_hintFor', () {
    test('recognizes known providers by port', () {
      const discovery = DeviceAiDiscovery();
      expect(discovery.hintForPort(1234), contains('LM Studio'));
      expect(discovery.hintForPort(11434), contains('Ollama'));
      expect(discovery.hintForPort(5273), contains('Foundry'));
      expect(discovery.hintForPort(9000), contains('Foundry'));
      expect(discovery.hintForPort(55588), contains('Foundry'));
      expect(discovery.hintForPort(55589), contains('Foundry'));
      expect(discovery.hintForPort(9999), isNull);
    });
  });
}
