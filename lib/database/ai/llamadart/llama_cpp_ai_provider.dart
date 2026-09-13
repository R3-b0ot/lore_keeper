import 'package:llamadart/llamadart.dart';

import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';

/// Default Hugging Face source for the bundled low-weight model.
///
/// SmolLM2-135M instruct (Q2_K, ~70 MB) is small enough for every machine yet
/// still produces usable embeddings and multi-turn text. It is downloaded on
/// first use and cached locally, so the installer stays lean.
const String bundledModelSource =
    'hf://unsloth/SmolLM2-135M-Instruct-GGUF/SmolLM2-135M-Instruct-Q2_K.gguf';

/// Stable display identifier for the bundled model.
const String bundledModelId = 'SmolLM2-135M-Instruct-Q2_K';

/// Slim surface of the on-device inference engine consumed by
/// [LlamaCppAiProvider].
///
/// Kept as an interface so tests can substitute a fake runtime; the native
/// llama.cpp DLLs (resolved automatically by llamadart's build hook) and the
/// model download never run inside unit tests.
abstract class DeviceLlamaRuntime {
  /// Download (on first use) and load the model referenced by [modelSource].
  Future<void> loadModelSource(String modelSource);

  /// Embed [text] as a normalized vector.
  Future<List<double>> embed(String text, {bool normalize});

  /// Run a chat completion against [systemPrompt]/[userPrompt] and return the
  /// accumulated assistant text. Requires the model to be a chat-capable
  /// instruct model.
  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  });

  /// Release the loaded model from memory.
  Future<void> unloadModel();
}

/// Production [DeviceLlamaRuntime] built on llamadart's llama.cpp backend.
class LlamaDartRuntime implements DeviceLlamaRuntime {
  final LlamaEngine _engine = LlamaEngine(LlamaBackend());

  @override
  Future<void> loadModelSource(String modelSource) =>
      _engine.loadModelSource(ModelSource.parse(modelSource));

  @override
  Future<List<double>> embed(String text, {bool normalize = true}) =>
      _engine.embed(text, normalize: normalize);

  @override
  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in _engine.create(
      [
        LlamaChatMessage(role: 'system', content: systemPrompt),
        LlamaChatMessage(role: 'user', content: userPrompt),
      ],
      params: GenerationParams(
        temp: temperature ?? 0.7,
        maxTokens: maxTokens ?? 2048,
      ),
    )) {
      final choices = chunk.choices;
      final delta = choices.isEmpty ? null : choices.first.delta;
      final text = delta?.content;
      if (text != null && text.isNotEmpty) buffer.write(text);
    }
    return buffer.toString();
  }

  @override
  Future<void> unloadModel() => _engine.unloadModel();
}

/// An [AiProvider] that runs a bundled low-weight model entirely on-device.
///
/// No server, no endpoint: the llama.cpp runtime is shipped with the app and
/// the ~70 MB GGUF is downloaded from Hugging Face on first use, so AI
/// features work offline afterwards. `load()` returns false when the download
/// or model load fails and the Reference Engine keeps working deterministically.
class LlamaCppAiProvider implements AiProvider {
  final DeviceLlamaRuntime _runtime;
  final String _modelSource;

  bool _ready = false;

  /// Creates the provider, optionally overriding the [runtime] (tests) and the
  /// [modelSource] that is downloaded on first `load()`.
  LlamaCppAiProvider({DeviceLlamaRuntime? runtime, String? modelSource})
    : _runtime = runtime ?? LlamaDartRuntime(),
      _modelSource = modelSource ?? bundledModelSource;

  @override
  String get name => 'On-device bundled AI (llama.cpp)';

  @override
  String get modelId => _ready ? bundledModelId : '';

  @override
  String get modelVersion => 'unknown';

  @override
  bool get isReady => _ready;

  @override
  Future<bool> load() async {
    try {
      await _runtime.loadModelSource(_modelSource);
      _ready = true;
      return true;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  @override
  Future<List<double>?> embed(String text) async {
    if (!_ready) return null;
    try {
      return await _runtime.embed(text);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_ready) return null;
    try {
      final text = (await _runtime.chat(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      )).trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AiSuggestion>?> suggestRelated(EntityRef entityRef) async {
    // The contract passes only the entity reference, never a candidate set to
    // rank against, so there is nothing to re-rank here. Deterministic
    // suggestions remain the Reference Engine's job; this provider powers the
    // embedding-based semantic functions instead.
    return null;
  }

  @override
  Future<void> unload() async {
    try {
      await _runtime.unloadModel();
    } finally {
      _ready = false;
    }
  }
}
