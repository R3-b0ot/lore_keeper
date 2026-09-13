import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single model offered by an OpenAI-compatible server.
class OpenAiModelInfo {
  /// The model identifier used in chat/embedding requests.
  final String id;

  const OpenAiModelInfo(this.id);
}

/// A chat message in the OpenAI `messages` format.
class OpenAiChatMessage {
  /// `system`, `user`, or `assistant`.
  final String role;

  /// The message body.
  final String content;

  const OpenAiChatMessage(this.role, this.content);
}

/// A completed (non-streamed) chat response.
class OpenAiChatResult {
  /// The assistant's reply text.
  final String text;

  /// Prompt tokens reported in `usage`, when the server provides them.
  final int? promptTokens;

  /// Completion tokens reported in `usage`, when the server provides them.
  final int? completionTokens;

  const OpenAiChatResult({
    required this.text,
    this.promptTokens,
    this.completionTokens,
  });
}

/// A minimal OpenAI-compatible REST client.
///
/// Windows AI Foundry (Foundry Local), LM Studio, Ollama and similar local
/// engines all expose this same HTTP surface (`/v1/models`,
/// `/v1/chat/completions`, `/v1/embeddings`), so one client covers every
/// local/device provider uniformly.
class OpenAiCompatibleClient {
  final http.Client _http;
  final Uri _base;
  final String? _apiKey;
  final Duration _timeout;

  /// Creates a client rooted at [baseUrl] (e.g. `http://localhost:1234/v1`).
  ///
  /// [client] allows test injection; [apiKey] is optional because local
  /// engines typically ignore authentication.
  OpenAiCompatibleClient({
    required String baseUrl,
    http.Client? client,
    String? apiKey,
    Duration timeout = const Duration(seconds: 30),
  }) : _http = client ?? http.Client(),
       _base = _normalize(baseUrl),
       _apiKey = apiKey,
       _timeout = timeout;

  /// Normalize a base URL so API paths append cleanly below it.
  static Uri _normalize(String baseUrl) {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withScheme = trimmed.startsWith('http') ? trimmed : 'http://$trimmed';
    return Uri.parse(withScheme);
  }

  /// Build a fully-qualified URL for an API path under the base.
  Uri _path(String path) =>
      _base.replace(path: '${_base.path}/$path'.replaceAll('//', '/'));

  Map<String, String> _headers({bool jsonBody = false}) => {
    if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
    if (jsonBody) 'Content-Type': 'application/json',
  };

  /// List available models. Returns null when the server is unreachable or
  /// does not speak the OpenAI-compatible protocol.
  Future<List<OpenAiModelInfo>?> listModels() async {
    try {
      final resp = await _http
          .get(_path('models'), headers: _headers())
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! List) return null;
      return [
        for (final entry in data)
          if (entry is Map<String, dynamic> && entry['id'] is String)
            OpenAiModelInfo(entry['id'] as String),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Run a chat completion. Returns null on transport or protocol failure.
  Future<OpenAiChatResult?> chat({
    required String model,
    required List<OpenAiChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) async {
    try {
      final body = <String, dynamic>{
        'model': model,
        'messages': [
          for (final m in messages) {'role': m.role, 'content': m.content},
        ],
        'stream': false,
        if (temperature != null) 'temperature': temperature,
        if (topP != null) 'top_p': topP,
        if (maxTokens != null) 'max_tokens': maxTokens,
      };
      final resp = await _http
          .post(
            _path('chat/completions'),
            headers: _headers(jsonBody: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map<String, dynamic>) return null;
      final message = first['message'];
      final text = message is Map<String, dynamic>
          ? (message['content'] as String? ?? '')
          : '';
      final usage = decoded['usage'];
      return OpenAiChatResult(
        text: text,
        promptTokens: usage is Map<String, dynamic>
            ? (usage['prompt_tokens'] as num?)?.toInt()
            : null,
        completionTokens: usage is Map<String, dynamic>
            ? (usage['completion_tokens'] as num?)?.toInt()
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream a chat completion as `data:` SSE delta chunks.
  ///
  /// Emits an error when the request fails or the server rejects the payload
  /// (e.g. the model does not support streaming).
  Stream<String> chatStream({
    required String model,
    required List<OpenAiChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) async* {
    final body = <String, dynamic>{
      'model': model,
      'messages': [
        for (final m in messages) {'role': m.role, 'content': m.content},
      ],
      'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (maxTokens != null) 'max_tokens': maxTokens,
    };
    final request = http.Request('POST', _path('chat/completions'))
      ..headers.addAll(_headers(jsonBody: true))
      ..body = jsonEncode(body);
    final streamed = await _http.send(request).timeout(_timeout);
    if (streamed.statusCode != 200) {
      throw http.ClientException('Chat failed (${streamed.statusCode})');
    }
    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload == '[DONE]') break;
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) continue;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final first = choices.first;
      if (first is! Map<String, dynamic>) continue;
      final delta = first['delta'];
      final content = delta is Map<String, dynamic> ? delta['content'] : null;
      if (content is String) yield content;
    }
  }

  /// Embed [text] with [model]. Returns null when embeddings are unsupported
  /// (e.g. a chat-only local engine) or the request fails.
  Future<List<double>?> embed(String model, String text) async {
    try {
      final resp = await _http
          .post(
            _path('embeddings'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({'model': model, 'input': text}),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map<String, dynamic>) return null;
      final embedding = first['embedding'];
      if (embedding is! List) return null;
      return [for (final value in embedding) (value as num).toDouble()];
    } catch (_) {
      return null;
    }
  }
}
