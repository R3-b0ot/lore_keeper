import 'package:http/http.dart' as http;

import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/ai/device_ai/openai_compatible_client.dart';
import 'package:lore_keeper/database/entity_ref.dart';

/// An [AiProvider] backed by any OpenAI-compatible local engine.
///
/// Windows AI Foundry (Foundry Local), LM Studio, Ollama and cloud OpenAI all
/// expose the same `/v1` surface, so this single implementation connects to
/// them uniformly. `load()` only verifies the endpoint; heavy model setup is
/// the engine's responsibility (Foundry downloads/keeps models on demand).
class OpenAiHttpAiProvider implements AiProvider {
  final OpenAiCompatibleClient _client;
  final String? _requestedModelId;

  bool _ready = false;
  String _activeModelId = '';

  OpenAiHttpAiProvider({
    required String baseUrl,
    String? modelId,
    String? apiKey,
    http.Client? client,
  }) : _client = OpenAiCompatibleClient(
         baseUrl: baseUrl,
         apiKey: apiKey,
         client: client,
       ),
       _requestedModelId = (modelId == null || modelId.isEmpty)
           ? null
           : modelId;

  @override
  String get name => 'OpenAI-compatible device AI';

  @override
  String get modelId => _activeModelId;

  @override
  String get modelVersion => 'unknown';

  @override
  bool get isReady => _ready;

  @override
  Future<bool> load() async {
    final models = await _client.listModels();
    if (models == null || models.isEmpty) {
      _ready = false;
      return false;
    }
    final requested = _requestedModelId;
    if (requested != null && models.any((m) => m.id == requested)) {
      _activeModelId = requested;
    } else {
      _activeModelId = models.first.id;
    }
    _ready = true;
    return true;
  }

  @override
  Future<void> unload() async {
    _ready = false;
    _activeModelId = '';
  }

  @override
  Future<List<double>?> embed(String text) {
    if (!_ready) return Future.value(null);
    return _client.embed(_activeModelId, text);
  }

  @override
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_ready) return null;
    final result = await _client.chat(
      model: _activeModelId,
      messages: [
        OpenAiChatMessage('system', systemPrompt),
        OpenAiChatMessage('user', userPrompt),
      ],
      temperature: temperature,
      maxTokens: maxTokens,
    );
    final text = result?.text.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  @override
  Future<List<AiSuggestion>?> suggestRelated(EntityRef entityRef) async {
    // The contract only passes the entity reference, never a candidate set,
    // so a remote LLM has nothing to rank against. Deterministic suggestions
    // remain the Reference Engine's job.
    return null;
  }
}
