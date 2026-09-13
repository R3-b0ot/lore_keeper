import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/ai/llamadart/llama_cpp_ai_provider.dart';
import 'package:lore_keeper/database/ai/openai_http_ai_provider.dart';

/// Canonical AI provider names shown in the settings UI and persisted as the
/// `aiProvider` setting value.
abstract final class AiProviders {
  /// A local OpenAI-compatible server (LM Studio, Ollama, …).
  static const String local = 'Local (LM Studio / Ollama)';

  /// OpenAI's hosted chat API.
  static const String openAi = 'OpenAI API';

  /// Anthropic's hosted messages API.
  static const String anthropic = 'Anthropic API';

  /// The device's native runtime — Windows AI Foundry (Foundry Local) — as
  /// exposed through its local OpenAI-compatible endpoint.
  static const String deviceFoundry = 'Device AI (Windows AI Foundry)';

  /// A low-weight model bundled with the app, running locally through
  /// llama.cpp. No server or endpoint required; the model is downloaded on
  /// first AI use and cached.
  static const String onDevice = 'Bundled On-Device AI';
}

/// Builds the runtime [AiProvider] from the persisted AI settings.
///
/// Returns a [NullAiProvider] (which the Reference Engine treats as "no AI")
/// whenever AI is disabled or the selected provider cannot be reached through
/// an OpenAI-compatible endpoint. This keeps the engine fully functional on
/// machines without any local model.
AiProvider buildAiProviderFromSettings({
  required bool enabled,
  required String provider,
  required String endpoint,
  required String model,
}) {
  if (!enabled) return const NullAiProvider();
  if (provider == AiProviders.onDevice) {
    return LlamaCppAiProvider();
  }
  final isOpenAiCompatible =
      provider == AiProviders.local ||
      provider == AiProviders.deviceFoundry ||
      provider == AiProviders.openAi;
  if (!isOpenAiCompatible) return const NullAiProvider();
  final trimmed = endpoint.trim();
  if (trimmed.isEmpty) return const NullAiProvider();
  return OpenAiHttpAiProvider(
    baseUrl: trimmed,
    modelId: model.trim().isEmpty ? null : model.trim(),
  );
}
