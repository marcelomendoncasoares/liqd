<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# How to wire open router to Dart? I want to call LLM models at open router from a Dart backend

Yes — the simplest way from a Dart backend is to call OpenRouter’s OpenAI-compatible endpoint directly with `dart:io` `HttpClient` or an HTTP package. OpenRouter’s docs say the main endpoint is `https://openrouter.ai/api/v1/chat/completions`, authenticated with `Authorization: Bearer <key>`, and the optional attribution headers are `HTTP-Referer` and `X-OpenRouter-Title`.[^1_1][^1_2]

## Basic wiring

For a Dart backend, you only need:

- An OpenRouter API key stored in an environment variable, not hardcoded in source.[^1_2]
- A POST request to `/api/v1/chat/completions`.[^1_1]
- A model slug such as `openai/gpt-5.2` or one of the “latest” aliases like `~openai/gpt-latest`.[^1_2][^1_1]

Example with `package:http/http.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterClient {
  OpenRouterClient({
    required this.apiKey,
    this.siteUrl,
    this.appName,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String? siteUrl;
  final String? appName;
  final http.Client _http;

  Future<String> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
  }) async {
    final response = await _http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        if (siteUrl != null) 'HTTP-Referer': siteUrl!,
        if (appName != null) 'X-OpenRouter-Title': appName!,
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenRouter error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['choices'][^1_0]['message']['content'] as String;
  }

  void close() => _http.close();
}
```

Usage:

```dart
final client = OpenRouterClient(
  apiKey: Platform.environment['OPENROUTER_API_KEY']!,
  siteUrl: 'https://yourapp.com',
  appName: 'Your Dart Backend',
);

final text = await client.chat(
  model: '~openai/gpt-latest',
  messages: [
    {'role': 'system', 'content': 'You are a concise backend assistant.'},
    {'role': 'user', 'content': 'Explain CRDTs in one paragraph.'},
  ],
);

print(text);
```

That matches OpenRouter’s documented request shape: a `model` plus a `messages` array sent to the chat completions endpoint.[^1_1]

## Backend pattern

A good production pattern is to wrap OpenRouter behind your own service class so the rest of your Dart backend never sees raw HTTP details. OpenRouter exposes one unified API for many models, so that wrapper can accept the model slug as a parameter and swap providers without changing the rest of your code.[^1_1]

A practical service interface looks like this:

```dart
abstract class LlmGateway {
  Future<String> generateText({
    required String prompt,
    String model = '~openai/gpt-latest',
  });
}

class OpenRouterGateway implements LlmGateway {
  OpenRouterGateway(this.client);
  final OpenRouterClient client;

  @override
  Future<String> generateText({
    required String prompt,
    String model = '~openai/gpt-latest',
  }) {
    return client.chat(
      model: model,
      messages: [
        {'role': 'user', 'content': prompt},
      ],
    );
  }
}
```

This keeps your app portable if you later want retries, model fallback, usage logging, or per-feature model selection. OpenRouter explicitly positions the API as a single endpoint for access to many models, which fits this abstraction well.[^1_1]

## Streaming

OpenRouter supports streaming when you set `"stream": true` in the request body.[^1_3][^1_1]

If you want token streaming in Dart, use `http.Request` and read the byte stream incrementally:

```dart
Future<void> streamChat({
  required String apiKey,
  required String model,
  required List<Map<String, dynamic>> messages,
}) async {
  final request = http.Request(
    'POST',
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
  );

  request.headers.addAll({
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  });

  request.body = jsonEncode({
    'model': model,
    'messages': messages,
    'stream': true,
  });

  final streamed = await request.send();

  if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
    final body = await streamed.stream.bytesToString();
    throw Exception('OpenRouter error ${streamed.statusCode}: $body');
  }

  await for (final chunk in streamed.stream.transform(utf8.decoder)) {
    // Parse SSE-style chunks here.
    print(chunk);
  }
}
```

In practice, you’ll want an SSE parser because streamed responses arrive in chunks rather than one final JSON object. The key point is that OpenRouter enables this with the `stream` flag on the same endpoint.[^1_3][^1_1]

## Notes for Dart servers

- Keep the key in `OPENROUTER_API_KEY` or similar environment config, because OpenRouter recommends environment variables and warns against exposing keys in code or public repos.[^1_2]
- Add short timeouts and retry only for transient failures, because model calls can be slower than typical REST APIs.[^1_1]
- Pass the model slug from config, not constants scattered through the codebase, because OpenRouter supports many models and “latest” aliases.[^1_1]
- If you want a Dart-native wrapper instead of raw HTTP, there is also a pub package called `openrouter_api` that advertises chat and streaming support plus optional app headers.[^1_4]


## Minimal Serverpod example

Since you’re working from a Dart backend, a Serverpod-style endpoint wrapper could look like:

```dart
class AiService {
  AiService()
      : _client = OpenRouterClient(
          apiKey: Platform.environment['OPENROUTER_API_KEY']!,
          siteUrl: 'https://yourapp.com',
          appName: 'your-backend',
        );

  final OpenRouterClient _client;

  Future<String> answer(String prompt) {
    return _client.chat(
      model: 'openai/gpt-5.2',
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
    );
  }
}
```

Then your endpoint just calls `AiService.answer(...)` and returns the string. That works because OpenRouter’s API is plain HTTP and language-agnostic, not tied to any JS-only SDK.[^1_1]

Would you like a version tailored for Serverpod with dependency injection, retries, and SSE streaming support?
<span style="display:none">[^1_10][^1_11][^1_12][^1_13][^1_14][^1_15][^1_5][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://www.youtube.com/watch?v=vKWz4zdxrvU

[^1_2]: https://openrouter.ai/docs/quickstart

[^1_3]: https://openrouter.ai/docs/api/reference/streaming

[^1_4]: https://pub.dev/packages/openrouter_api

[^1_5]: https://www.youtube.com/watch?v=sgQwF1aOu9U

[^1_6]: https://github.com/simonw/llm-openrouter

[^1_7]: https://openrouter.ai/docs/api/reference/authentication

[^1_8]: https://openrouter.ai/docs/api/api-reference/o-auth/create-auth-keys-code

[^1_9]: https://openrouter.ai/docs/sdks/typescript/call-model/streaming

[^1_10]: https://snyk.io/articles/openrouter-in-python-use-any-llm-with-one-api-key/

[^1_11]: https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request

[^1_12]: https://openrouter.ai/docs/api/api-reference/models/get-models

[^1_13]: https://www.reddit.com/r/LLMDevs/comments/1in9g1n/openrouter_experience/

[^1_14]: https://openrouter.ai/docs/api/reference/overview

[^1_15]: https://gist.github.com/rbiswasfc/f38ea50e1fa12058645e6077101d55bb


---

# I want to use together with GenUI

Yes — that’s a good fit. GenUI is designed to work with your own agent provider, and the Flutter docs explicitly say you can build your own adapter and stream results into an `A2uiTransportAdapter`, while the GenUI repo says it can integrate with any LLM that can generate structured JSON output.[^2_1][^2_2]

## Fit with GenUI

The clean architecture is: Flutter app with GenUI on the client, your Dart backend in the middle, and OpenRouter as the LLM provider behind that backend. GenUI’s docs describe this pattern through `SurfaceController`, `PromptBuilder`, `Conversation`, and `A2uiTransportAdapter`, where your app streams model output chunks into the transport adapter.[^2_1]

So OpenRouter is not something GenUI “natively” needs to know about; your backend just needs to call OpenRouter and return text or streamed chunks in the format your GenUI transport expects. Because OpenRouter offers an OpenAI-compatible API and unified model access, it works well as the model layer under that transport.[^2_3][^2_4]

## Recommended shape

Use this split:

- Flutter client: `genui`, widget catalog, `SurfaceController`, `Conversation`, `A2uiTransportAdapter`.[^2_1]
- Dart backend: prompt assembly, auth, tool policy, OpenRouter HTTP client, streaming proxy.[^2_4][^2_1]
- OpenRouter: actual model routing and model selection.[^2_5][^2_4]

This is the key point: GenUI wants an agent that can emit UI instructions and text over a stream, and OpenRouter gives you the LLM endpoint; your backend is the adapter between those two worlds.[^2_2][^2_1]

## How to wire it

On the Flutter side, follow the GenUI pattern:

1. Build your `Catalog` and `SurfaceController`.[^2_1]
2. Build a `PromptBuilder.chat(...)` and include the GenUI tool instructions in the system prompt.[^2_1]
3. In `A2uiTransportAdapter(onSend: ...)`, send the user message to your backend instead of directly to Firebase or another SDK.[^2_1]
4. As your backend streams model output, feed each chunk into `transportAdapter.addChunk(...)`.[^2_1]

On the backend side:

1. Accept the user message plus the GenUI system prompt from the client, or reconstruct the prompt server-side.[^2_1]
2. Send that prompt to OpenRouter using `chat/completions` or the OpenAI-compatible Responses API.[^2_3][^2_4]
3. Stream delta text back to the Flutter app.
4. Let `A2uiTransportAdapter` parse the stream and update GenUI surfaces.[^2_1]

## Practical backend contract

A simple backend API for GenUI + OpenRouter is:

- `POST /ai/chat`: non-streaming fallback, returns final text/UI payload.
- `GET or WS /ai/chat/stream`: streams token chunks from OpenRouter to Flutter.
- Optional `model`, `conversationId`, and `catalogVersion` fields so you can swap models without changing the client.[^2_4][^2_1]

Example request body from Flutter to your Dart backend:

```json
{
  "model": "anthropic/claude-sonnet-4",
  "systemPrompt": "PromptBuilder output here...",
  "messages": [
    {"role": "user", "content": "Help me plan a trip to Kyoto"}
  ]
}
```

Then your backend forwards that to OpenRouter as a standard chat completion request. OpenRouter’s docs describe that request shape as OpenAI-compatible with `model` and `messages`.[^2_5][^2_4]

## Example flow

Here is the mental model:

```dart
// Flutter
_transportAdapter = A2uiTransportAdapter(
  onSend: (message) async {
    final stream = backendClient.streamGenUi(
      text: extractUserText(message),
      systemPrompt: promptBuilder.systemPromptJoined(),
    );

    await for (final chunk in stream) {
      _transportAdapter.addChunk(chunk);
    }
  },
);
```

That matches GenUI’s documented pattern of implementing your own provider connection and pumping streamed chunks into `A2uiTransportAdapter`.[^2_1]

And on the Dart backend:

```dart
Stream<String> streamOpenRouter({
  required String apiKey,
  required String model,
  required String systemPrompt,
  required String userText,
}) async* {
  final request = http.Request(
    'POST',
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
  );

  request.headers.addAll({
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  });

  request.body = jsonEncode({
    'model': model,
    'stream': true,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  });

  final response = await request.send();
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    yield chunk;
  }
}
```

OpenRouter supports streaming on the same API family, and GenUI is built to consume streamed model output through its transport adapter.[^2_6][^2_1]

## Important detail

The most important part is the prompt. GenUI’s docs say the system instructions must explicitly tell the model to use the provided UI tools, and `PromptBuilder` exists to build those instructions around your catalog.[^2_1]

So if you use OpenRouter with GenUI, do **not** just send a plain “helpful assistant” prompt. Send `promptBuilder.systemPromptJoined()` or an equivalent server-generated prompt that includes the catalog, tool instructions, and rules about when to generate surfaces versus plain text.[^2_1]

## Recommendation

For your setup, I’d do this:

- Flutter: GenUI only.
- Dart backend: one `GenUiAgentService` that owns prompt building, conversation state, and OpenRouter calls.
- OpenRouter model choice: start with a strong tool-capable model and keep model ID configurable per feature. OpenRouter is specifically meant to let you swap among many providers through one interface.[^2_4][^2_5]

A very practical architecture is:

- `GenUiPromptService`
- `OpenRouterClient`
- `GenUiStreamController`
- `AiEndpoint` or `Serverpod Endpoint`

That gives you one place to normalize OpenRouter streaming into the chunk format your Flutter GenUI adapter expects.[^2_4][^2_1]

Would you like me to sketch a concrete end-to-end example with:

1. Flutter `genui` client code,
2. Dart backend endpoint,
3. OpenRouter streaming parser for SSE chunks?
<span style="display:none">[^2_10][^2_11][^2_12][^2_13][^2_14][^2_15][^2_16][^2_17][^2_18][^2_7][^2_8][^2_9]</span>

<div align="center">⁂</div>

[^2_1]: https://pub.dev/packages/openrouter_api

[^2_2]: https://www.youtube.com/watch?v=sgQwF1aOu9U

[^2_3]: https://openrouter.ai/docs/api/reference/responses/overview

[^2_4]: https://openrouter.ai/docs/quickstart

[^2_5]: https://openrouter.ai/docs/api/reference/overview

[^2_6]: https://openrouter.ai/docs/api/reference/streaming

[^2_7]: https://openrouter.ai/openai

[^2_8]: https://docs.agno.com/reference/models/openrouter-responses

[^2_9]: https://github.com/flutter/genui

[^2_10]: https://www.reddit.com/r/OpenWebUI/comments/1kt1l1z/what_are_your_recommendations_for_unified_ai/

[^2_11]: https://docs.getbifrost.ai/providers/supported-providers/openrouter

[^2_12]: https://docs.flutter.dev/ai/genui/get-started

[^2_13]: https://github.com/simonw/llm-openrouter

[^2_14]: https://fal.ai/models/openrouter/router/openai/v1/responses

[^2_15]: https://codewithandrea.com/newsletter/december-2025/

[^2_16]: https://openrouter.ai/openrouter/free

[^2_17]: https://github.com/open-responses/open-responses

[^2_18]: https://www.youtube.com/watch?v=nWr6eZKM6no


---

# Does the dart backend need to have Flutter installed if I'm going to generate the widgets from the backend?

No — your Dart backend does **not** need Flutter installed just because it is choosing or generating the widget structure. GenUI’s docs say the backend can be any stack that returns the correct JSON-based UI format, while the actual rendering happens in the Flutter app from the app’s existing widget catalog.[^3_1][^3_2][^3_3]

## What runs where

The Flutter side needs GenUI and the widget catalog, because GenUI composes UI at runtime from widgets already defined in your Flutter project. The GitHub README is explicit that the UI is not generated as Dart/Flutter code; it is generated at runtime from a JSON-based format and your existing catalog.[^3_2][^3_3]

Your backend only needs to:

- Build prompts.
- Call OpenRouter.
- Return structured JSON or streamed chunks.
- Maintain conversation or tool state if you want.[^3_3][^3_2]


## When Flutter is needed

You only need Flutter installed on the backend machine if that machine is also going to do Flutter-specific work such as compiling the app, running widget tests, generating Flutter artifacts, or sharing code that imports Flutter packages. GenUI itself is described as an orchestration layer inside the Flutter application, not a requirement for the server runtime.[^3_2][^3_3]

So there are really two different meanings of “generate widgets”:

- Generate **widget intent/schema/JSON** on the backend: no Flutter required on the server.[^3_1][^3_3]
- Generate actual **Flutter code/widgets and render them** on the server: that is not the normal GenUI model, and then you would be in codegen/build territory.[^3_2]


## Best architecture

The cleanest setup is:

- Backend: pure Dart service that outputs GenUI-compatible JSON.
- Client: Flutter app with the real widget catalog and GenUI renderer.
- LLM: OpenRouter behind the backend.[^3_3][^3_2]

A good mental model is that the backend sends something like “render a slider with these bounds and a date picker with this label,” and the Flutter app maps that to real widgets from your catalog. The GenUI docs describe exactly this JSON-based composition flow and state loop between agent and Flutter UI.[^3_3][^3_2]

## Practical answer

If your backend is just:

- asking OpenRouter for a structured response,
- validating it,
- and forwarding it to the app,

then install only Dart on the server, not Flutter. That fits GenUI’s documented “framework agnostic / any backend” model and keeps your server much lighter.[^3_1][^3_2]

If you want, I can sketch the exact JSON contract your Dart backend should return so it plugs cleanly into a Flutter GenUI client.
<span style="display:none">[^3_10][^3_11][^3_12][^3_13][^3_14][^3_15][^3_16][^3_17][^3_4][^3_5][^3_6][^3_7][^3_8][^3_9]</span>

<div align="center">⁂</div>

[^3_1]: https://www.youtube.com/watch?v=Dum-LYLm0Uw

[^3_2]: https://openrouter.ai/docs/quickstart

[^3_3]: https://www.youtube.com/watch?v=vKWz4zdxrvU

[^3_4]: https://verygood.ventures/blog/getting-started-with-genui/

[^3_5]: https://pub.dev/packages/genui

[^3_6]: https://www.youtube.com/watch?v=nWr6eZKM6no

[^3_7]: https://www.freecodecamp.org/news/how-to-use-genui-in-flutter-to-build-dynamic-ai-driven-interfaces/

[^3_8]: https://www.reddit.com/r/FlutterDev/comments/1rikrs9/flutter_dynamic_widgets_from_json_mcp_tools_where/

[^3_9]: https://docs.flutter.dev/ai/genui

[^3_10]: https://github.com/flutter/genui

[^3_11]: https://docs.flutter.dev/ai/genui/get-started

[^3_12]: https://www.reddit.com/r/FlutterDev/comments/1p3wpcr/excited_for_genui/

[^3_13]: https://www.linkedin.com/posts/mcroghan_github-fluttergenui-activity-7395163098522791936-6XJC

[^3_14]: https://verygood.ventures/blog/flutter-genui-meets-the-vgv-architecture/

[^3_15]: https://www.linkedin.com/posts/very-good-ventures_ai-genui-flutter-activity-7450546222605500417-CXtW

[^3_16]: https://docs.flutter.dev/ai/create-with-ai

[^3_17]: https://atuoha.hashnode.dev/using-genui-in-flutter-to-build-dynamic-ai-driven-interfaces


---

# So it is the frontend that talks directly to the model?

Not necessarily. With GenUI, the frontend can talk directly to a model provider, or it can talk to your own backend proxy; the package is backend-agnostic and asks you to implement the `onSend` bridge in `A2uiTransportAdapter` for whatever agent provider architecture you choose.[^4_1]

## Two valid patterns

The frontend-direct pattern is common in GenUI demos that use Firebase AI Logic, where the Flutter app connects to the model service from the client side. Firebase’s docs explicitly say their client SDKs let mobile or web apps call the model directly.[^4_2][^4_3]

The backend-proxy pattern is also fully valid: the frontend sends the message to your Dart backend, your backend calls OpenRouter, and then streams the result back to the app. GenUI supports this because `A2uiTransportAdapter` is just the transport bridge, not a mandate that the client must own model access.[^4_4][^4_1]

## For OpenRouter

If you are using OpenRouter, I would strongly recommend **not** calling it directly from the Flutter frontend. OpenRouter uses API-key authentication on the request, so putting that key in a client app is a bad security model unless you build an additional secure token/proxy layer.[^4_5][^4_6]

So for your case, the right mental model is:

- Flutter frontend talks to your Dart backend.
- Dart backend talks to OpenRouter.
- GenUI in Flutter renders the structured UI and chat stream.[^4_1][^4_5]


## Rule of thumb

Use direct frontend-to-model only when the provider offers a client-safe access layer specifically designed for that, like Firebase AI Logic’s client SDK approach.[^4_2]

Use a backend proxy when you need secret API keys, routing across multiple providers, logging, rate limiting, tool execution, or business logic; that is the better fit for OpenRouter and for most production apps.[^4_4][^4_1]

In your setup, the frontend should usually talk to **your backend**, not directly to OpenRouter.
<span style="display:none">[^4_10][^4_11][^4_12][^4_13][^4_14][^4_15][^4_16][^4_17][^4_7][^4_8][^4_9]</span>

<div align="center">⁂</div>

[^4_1]: https://pub.dev/packages/genui

[^4_2]: https://firebase.google.com/docs/ai-logic

[^4_3]: https://codelabs.developers.google.com/codelabs/genui-intro

[^4_4]: https://www.youtube.com/watch?v=Dum-LYLm0Uw

[^4_5]: https://openrouter.ai/docs/quickstart

[^4_6]: https://openrouter.ai/docs/api/reference/authentication

[^4_7]: https://www.youtube.com/watch?v=pSritFeoYFo

[^4_8]: https://webexpo.net/prague2025/sessions/from-genai-to-genui-codify-your-ui-on-the-fly/

[^4_9]: https://developers.googleblog.com/introducing-a2ui-an-open-project-for-agent-driven-interfaces/

[^4_10]: https://verygood.ventures/blog/genai-vs-genui-whats-the-difference-why-it-matters-for-product-teams/

[^4_11]: https://ridewithvia.com/resources/agent-user-interaction-protocol-when-the-frontend-got-an-ai-protocol

[^4_12]: https://www.youtube.com/watch?v=zCGzM0JxvRg

[^4_13]: https://docs.ag2.ai/latest/docs/blog/2026/03/20/AG2-A2UI/

[^4_14]: https://www.reddit.com/r/softwarearchitecture/comments/1kt6idk/frontend_team_being_asked_to_integrate_with_3/

[^4_15]: https://www.assistant-ui.com/docs/runtimes/custom/overview

[^4_16]: https://firebase.blog/posts/2025/11/gemini-3-firebase-ai-logic/

[^4_17]: https://www.linkedin.com/posts/ifeolulesi_someone-recently-asked-me-but-what-do-you-activity-7419268749943341057-dA_r

