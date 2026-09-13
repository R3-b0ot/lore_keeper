import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:lore_keeper/database/ai/device_ai/openai_compatible_client.dart';

/// A discovered OpenAI-compatible endpoint on this machine.
class DeviceAiEndpoint {
  /// Base URL including the `/v1` segment.
  final String baseUrl;

  /// Friendly hint of what engine was found, when it can be identified.
  final String? providerHint;

  /// Models advertised by the endpoint.
  final List<OpenAiModelInfo> models;

  const DeviceAiEndpoint({
    required this.baseUrl,
    required this.models,
    this.providerHint,
  });

  /// Model identifiers exposed by this endpoint.
  List<String> get modelIds => [for (final m in models) m.id];
}

/// Discovers local OpenAI-compatible AI runtimes.
///
/// Windows AI Foundry (Foundry Local), LM Studio and Ollama all serve a very
/// similar `GET /v1/models` response, so probing loopback listeners lets the
/// app offer "device AI" without hard-coding a single engine or port.
class DeviceAiDiscovery {
  /// Common default ports used by popular local engines. Kept small so a
  /// full probe stays fast; the authoritative list is what the OS reports as
  /// listening.
  static const List<int> knownPorts = [
    1234, // LM Studio
    11434, // Ollama
    5273, // Foundry Local daemon (common default)
    9000, // Foundry Local (server / proxy default)
    55588, // Foundry Local C# SDK web service
    55589, // Foundry Local Python SDK web service
  ];

  /// Per-port probe timeout; local endpoints answer quickly or not at all.
  static const Duration probeTimeout = Duration(milliseconds: 600);

  final List<int> _knownPorts;
  final Duration _probeTimeout;

  /// Test-injectable HTTP client used when the caller passes none.
  final http.Client? client;

  /// Creates a discovery scan.
  ///
  /// [client] allows test injection; [knownPorts] and [probeTimeout] keep the
  /// scan configurable so tests stay fast and isolated.
  const DeviceAiDiscovery({
    this.client,
    Duration probeTimeout = DeviceAiDiscovery.probeTimeout,
    List<int> knownPorts = DeviceAiDiscovery.knownPorts,
  }) : _probeTimeout = probeTimeout,
       _knownPorts = knownPorts;

  /// Probe every candidate loopback port for an OpenAI-compatible `/v1/models`.
  ///
  /// On Windows the OS TCP listener table is consulted first so the scan
  /// covers installed engines even when they move off their default port.
  Future<List<DeviceAiEndpoint>> discover({http.Client? client}) async {
    final http.Client? effectiveClient = client ?? this.client;
    final ports = <int>{..._knownPorts};
    if (Platform.isWindows) {
      ports.addAll(await _netstatListeners());
    }
    final probes = await Future.wait(
      ports.map((port) => _probe(port, effectiveClient)),
    );
    return [
      for (final probe in probes)
        if (probe != null) probe,
    ];
  }

  Future<DeviceAiEndpoint?> _probe(int port, http.Client? client) async {
    final baseUrl = 'http://127.0.0.1:$port/v1';
    final probe = OpenAiCompatibleClient(
      baseUrl: baseUrl,
      client: client,
      timeout: _probeTimeout,
    );
    final models = await probe.listModels();
    if (models == null || models.isEmpty) return null;
    return DeviceAiEndpoint(
      baseUrl: baseUrl,
      models: models,
      providerHint: hintForPort(port),
    );
  }

  /// Best-effort label identifying the engine listening on [port].
  ///
  /// Windows Foundry Local serves a `/openai/status` endpoint; classically
  /// it also answers on the daemon port.
  String? hintForPort(int port) {
    if (const {5273, 9000, 55588, 55589}.contains(port)) {
      return 'Windows AI Foundry (Foundry Local)';
    }
    if (port == 11434) return 'Ollama';
    if (port == 1234) return 'LM Studio';
    return null;
  }

  /// Enumerate loopback TCP listeners from `netstat` so engines listening on
  /// non-default ports are still discovered. Returns an empty list when
  /// netstat is unavailable.
  Future<List<int>> _netstatListeners() async {
    try {
      final result = await Process.run('netstat', ['-ano', '-p', 'tcp']);
      if (result.exitCode != 0) return const [];
      final ports = <int>{};
      final pattern = RegExp(
        r'TCP\s+(?:\[\:\:\]:|0\.0\.0\.0:|127\.0\.0\.1:|\[::1\]\:)(?<port>\d+)\s+\S+\s+LISTENING',
      );
      final lines = '${result.stdout}'.split('\n');
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        final port = match?.namedGroup('port');
        final parsed = port == null ? null : int.tryParse(port);
        if (parsed != null) ports.add(parsed);
      }
      return ports.toList();
    } catch (_) {
      return const [];
    }
  }
}
