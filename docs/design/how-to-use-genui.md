<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# How to use Flutter Genui package?

The Flutter **GenUI SDK** lets you replace static LLM text responses with dynamic, interactive UI built from your existing widget catalog. It is currently **highly experimental**, so expect breaking API changes as it evolves [^1_1][^1_2].

## Add Dependencies

Add `genui` to your `pubspec.yaml`. Depending on your AI backend, you may also need `firebase_vertex_ai` (for Firebase AI Logic) or `genui_a2a` (for A2A server architectures) [^1_3].

```bash
dart pub add genui firebase_vertex_ai
```


## Core Architecture

The SDK is an orchestration layer based on three main objects [^1_3]:

- **Catalog** — defines the widgets the AI is allowed to generate.
- **SurfaceController** — manages the lifecycle of generated UI *surfaces*.
- **Conversation** — wires the transport layer to the controller and handles the interaction loop.


## Initialize the SDK

Create a widget catalog, wrap your LLM in a transport adapter, and instantiate a `Conversation` [^1_3]:

```dart
import 'package:genui/genui.dart';
import 'package:firebase_vertex_ai/firebase_vertex_ai.dart';

final catalog = Catalog(components: [ /* your widgets */ ]);
final surfaceController = SurfaceController(catalogs: [catalog]);

final promptBuilder = PromptBuilder.chat(
  catalog: catalog,
  systemPromptFragments: ['You are a helpful assistant.'],
);

final model = FirebaseVertexAI.instance.generativeModel(
  model: 'gemini-2.5-flash',
  systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
);

late final A2uiTransportAdapter transportAdapter;
transportAdapter = A2uiTransportAdapter(onSend: (message) async {
  final stream = model.generateContentStream(...);
  await for (final chunk in stream) {
    transportAdapter.addChunk(chunk.text ?? '');
  }
});

final conversation = Conversation(
  controller: surfaceController,
  transport: transportAdapter,
);
```


## Send Requests and Render Surfaces

Listen to `conversation.events` for surface lifecycle updates, store the surface IDs, and render each with a `Surface` widget [^1_3]:

```dart
conversation.events.listen((event) {
  if (event is ConversationSurfaceAdded) _surfaceIds.add(event.surfaceId);
  if (event is ConversationSurfaceRemoved) _surfaceIds.remove(event.surfaceId);
});

// Inside your ListView/Column:
Surface(surfaceContext: _surfaceController.contextFor(surfaceId))
```


## Add Custom Widgets

Production apps typically extend the built-in catalog with custom widgets. For each one, define a JSON schema using `json_schema_builder`, create a `CatalogItem`, and register it with the `SurfaceController` [^1_3]:

```dart
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
    'question': S.string(description: 'The riddle question.'),
    'answer': S.string(description: 'The riddle answer.'),
  },
  required: ['question', 'answer'],
);

final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: _schema,
  widgetBuilder: ({required data, required id, required context, ...}) {
    final json = data as Map<String, Object?>;
    return Card(
      child: ListTile(
        title: Text(json['question'] as String),
        subtitle: Text(json['answer'] as String),
      ),
    );
  },
);

_surfaceController = SurfaceController(
  catalogs: [BasicCatalogItems.asCatalog().copyWith([riddleCard])],
);
```


## Data Binding

GenUI uses a centralized `DataModel`. Widgets bind to values via paths (for example `/user/name`). When an input widget updates the model, any other widgets bound to that path rebuild automatically, creating a reactive loop between the user, the UI, and the agent [^1_3].

## System Instructions

The LLM only generates UI if your system prompt explicitly instructs it to do so. Use `PromptBuilder` to inject catalog metadata and tell the agent when and which widgets to render [^1_3]:

```dart
final promptBuilder = PromptBuilder.chat(
  catalog: catalog,
  systemPromptFragments: [
    'Every time I give you a word, generate a RiddleCard '
    'that displays one new riddle related to that word.',
  ],
);
```


## Next Steps

For a complete guided build, check the official Google Codelab *"Build a Generative UI (GenUI) App"* and the example projects in the GitHub repository [^1_4][^1_1].
<span style="display:none">[^1_10][^1_5][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://github.com/flutter/genui

[^1_2]: https://docs.flutter.dev/ai/genui

[^1_3]: https://docs.flutter.dev/ai/genui/get-started

[^1_4]: https://codelabs.developers.google.com/codelabs/genui-intro

[^1_5]: https://www.youtube.com/watch?v=nWr6eZKM6no

[^1_6]: https://www.freecodecamp.org/news/how-to-use-genui-in-flutter-to-build-dynamic-ai-driven-interfaces/

[^1_7]: https://www.reddit.com/r/FlutterDev/comments/1pd29gq/a_look_at_the_new_flutter_genui_sdk/

[^1_8]: https://www.reddit.com/r/FlutterDev/comments/1p3wpcr/excited_for_genui/

[^1_9]: https://pub.dev/packages/flutter_gen_ai_chat_ui

[^1_10]: https://pub.dev/packages/flutter_genui


---

# Could I combine it with stac to allow building randomly generated widgets?

Yes — you can combine GenUI with Stac, and they complement each other well. GenUI already uses a JSON-based format to compose UI from a widget catalog [^2_1], while Stac renders Flutter widgets directly from JSON at runtime [^2_2][^2_3]. Together, they create a pipeline where the LLM generates arbitrary UI structures as JSON, and Stac instantiates them without any precompiled widget catalog.

## How the Integration Works

GenUI's core contract is: the model outputs structured JSON that describes which widgets to render and with what data [^2_4][^2_1]. Stac's core contract is: it receives structured JSON and renders native Flutter widgets from it [^2_2][^2_5]. Because both speak JSON, you can insert Stac as the rendering backend for GenUI-generated surfaces.

## Conceptual Architecture

```
┌─────────────┐     JSON payload      ┌─────────────┐     Flutter widget
│  GenUI LLM  │ ───────────────────▶ │    Stac     │ ───────────────────▶
│  response   │   (widget schema)     │  renderer   │    (runtime render)
└─────────────┘                       └─────────────┘
```

In practice, you would replace or extend GenUI's `widgetBuilder` in your `CatalogItem` to delegate rendering to Stac. Instead of hardcoding a Flutter widget for every catalog entry, you return a `Stac.fromJson()` call that parses the LLM-generated JSON dynamically [^2_3][^2_5].

## Example Integration Pattern

Register a single GenUI catalog item whose `widgetBuilder` forwards JSON to Stac:

```dart
import 'package:genui/genui.dart';
import 'package:stac/stac.dart';

final dynamicStacItem = CatalogItem(
  name: 'StacRenderer',
  dataSchema: S.object(properties: {
    'stacJson': S.object(description: 'Valid Stac widget JSON'),
  }),
  widgetBuilder: ({required data, required id, required context, ...}) {
    final json = data as Map<String, Object?>;
    final stacJson = json['stacJson'] as Map<String, Object?>;
    return Stac.fromJson(stacJson, context); // runtime render
  },
);
```

Then prompt the LLM to generate valid Stac JSON inside the `stacJson` field. Since Stac has parsers for Material widgets, layout primitives, and even forms, the LLM can theoretically generate any UI structure those parsers support [^2_2][^2_3].

## Why This Is Powerful

| Capability | GenUI Alone | GenUI + Stac |
| :-- | :-- | :-- |
| Widget catalog | Must predefine Dart widgets | Can generate arbitrary Stac-supported JSON |
| UI variety | Limited to registered catalog | Limited only by Stac parser coverage |
| Deployment | Requires app release for new widgets | New JSON schemas render immediately |
| Custom widgets | Dart `widgetBuilder` | Stac custom parsers + Dart fallback |

## Caveats

Both packages are evolving rapidly. GenUI is marked **highly experimental** with breaking API changes expected [^2_6][^2_1], and Stac's parser coverage for complex widgets may require custom parsers for production apps [^2_3][^2_7]. You would need to validate that the LLM consistently produces syntactically valid Stac JSON, possibly with a JSON schema constraint or a retry loop.

Do you want the LLM to generate Stac JSON from scratch, or would you constrain it to a predefined set of Stac templates?
<span style="display:none">[^2_10][^2_11][^2_12][^2_13][^2_14][^2_15][^2_16][^2_17][^2_8][^2_9]</span>

<div align="center">⁂</div>

[^2_1]: https://docs.flutter.dev/ai/genui

[^2_2]: https://pub.dev/packages/stac

[^2_3]: https://pub.dev/packages/stac/versions/0.11.0

[^2_4]: https://docs.flutter.dev/ai/genui/get-started

[^2_5]: https://github.com/StacDev/stac

[^2_6]: https://github.com/flutter/genui

[^2_7]: https://pub.dev/publishers/stac.dev/packages

[^2_8]: https://www.youtube.com/watch?v=DGJuBOWl-v0

[^2_9]: https://stac.dev

[^2_10]: https://dev.to/smartterss/stac-server-driven-ui-framework-for-flutter-701

[^2_11]: https://pub.dev/packages/stac/versions/1.3.1

[^2_12]: https://stackoverflow.com/questions/44306856/flutter-combine-dynamically-generated-elements-with-hard-coded-ones

[^2_13]: https://fluttergems.dev/widget-generation-rendering/

[^2_14]: https://www.linkedin.com/posts/divyanshub024_flutter-stacdev-serverdrivenui-activity-7313155064620027907-CfXP

[^2_15]: https://www.reddit.com/r/FlutterDev/comments/1qauk80/stac_v120_is_out_server_driven_ui_made_easy_for/

[^2_16]: https://www.youtube.com/watch?v=l41cLl32xhk

[^2_17]: https://pub.dev/packages/stac/versions


---

# How to feed data to a stac widget?

You feed data to a Stac widget by embedding it directly in the JSON that defines the UI. Stac renders whatever values are present in the JSON map at parse time, so the data layer and the widget structure travel together [^3_1][^3_2].

## Direct JSON Embedding

When using `Stac.fromJson()`, the JSON map itself carries the data values. For example, a `text` widget reads its content from the `'data'` field inside the JSON [^3_1]:

```dart
final json = {
  'type': 'scaffold',
  'body': {
    'type': 'center',
    'child': {
      'type': 'text',
      'data': 'Hello from JSON!'  // data fed directly into the widget
    }
  }
};

return Stac.fromJson(json, context);
```


## Dynamic Injection Before Rendering

If your data lives in a database or state manager, build the JSON programmatically and inject values before handing it to Stac:

```dart
final userName = await userRepository.getName();

final json = {
  'type': 'column',
  'children': [
    {
      'type': 'text',
      'data': 'Welcome, $userName'
    },
    {
      'type': 'text',
      'data': 'Balance: \$${account.balance}'
    }
  ]
};

return Stac.fromJson(json, context);
```


## Server-Driven Data with Network Requests

For truly dynamic content, `Stac.fromNetwork()` fetches JSON from an API that already bakes the latest data into the widget definition. You can also send parameters (like a user ID) in the request body so the server knows what data to embed [^3_1]:

```dart
Stac.fromNetwork(
  context: context,
  request: StacNetworkRequest(
    url: 'https://api.example.com/ui/dashboard',
    method: Method.post,
    body: {'userId': currentUser.id},
  ),
)
```


## Static Bundled Data

For offline-first scenarios, JSON files in your assets folder hold the data. These files are parsed at runtime via `Stac.fromAssets()` [^3_1]:

```dart
Stac.fromAssets(
  'assets/screens/offline_dashboard.json',
  loadingWidget: (context) => const CircularProgressIndicator(),
)
```


## GenUI Integration Pattern

In a GenUI + Stac pipeline, the LLM typically generates the *widget structure* while your app supplies the *data payload*. You can separate the two concerns by prompting the LLM to emit template JSON with placeholder keys, then merging it with real data before rendering:

```dart
// GenUI returns a widget skeleton
final stacTemplate = await genUI.generate('Show a user profile card');

// Your app injects live data
final populatedJson = injectData(stacTemplate, {'userName': user.name, 'avatarUrl': user.avatar});

return Stac.fromJson(populatedJson, context);
```

Because Stac does not automatically re-render when external state changes, you must rebuild the `Stac.fromJson()` call (for example, inside a `StreamBuilder` or `BlocBuilder`) whenever the underlying data updates.

Do you want to bind Stac widgets to reactive streams so they auto-update when data changes?
<span style="display:none">[^3_10][^3_11][^3_12][^3_13][^3_14][^3_15][^3_16][^3_17][^3_3][^3_4][^3_5][^3_6][^3_7][^3_8][^3_9]</span>

<div align="center">⁂</div>

[^3_1]: https://docs.flutter.dev/ai/genui/get-started

[^3_2]: https://www.youtube.com/watch?v=nWr6eZKM6no

[^3_3]: https://stackoverflow.com/questions/59473606/how-do-i-incorporate-data-from-a-json-to-a-widget-in-flutter

[^3_4]: https://www.youtube.com/watch?v=DGJuBOWl-v0

[^3_5]: https://pub.dev/packages/stac

[^3_6]: https://stac.mintlify.app/concepts/rendering_stac_widgets

[^3_7]: https://pub.dev/packages/stac/versions/0.11.0

[^3_8]: https://www.reddit.com/r/FlutterDev/comments/1kcxv4j/dynamic_interfaces_with_serverdriven_ui_for_mobile/

[^3_9]: https://pub.dev/documentation/stac/latest/

[^3_10]: https://pub.dev/packages/stac/versions/0.10.0

[^3_11]: https://stac.dev/blogs/tech-companies-sdui/

[^3_12]: https://stackoverflow.com/questions/54827081/state-management-in-a-generic-flutter-app-that-is-built-at-runtime

[^3_13]: https://www.reddit.com/r/FlutterDev/comments/1k1lkb8/passing_data_across_screenswidgets_in_flutter/

[^3_14]: https://www.youtube.com/watch?v=l41cLl32xhk

[^3_15]: https://fluttergems.dev/widget-generation-rendering/

[^3_16]: https://docs.flutter.dev/cookbook/navigation/passing-data

[^3_17]: https://github.com/stacdev


---

# Can I store the json widget on a local offline database, but fetch the data from an api and merge both before rendering?

Yes — since Stac only requires a plain JSON `Map<String, dynamic>` at runtime, you can store the widget structure locally, fetch data from an API separately, merge them in Dart, and then call `Stac.fromJson()` on the result [^4_1][^4_2].

## How the Separation Works

Stac does not natively distinguish between "template" and "data." A `text` widget, for example, reads its string directly from the `'data'` field inside the JSON [^4_1]. This means your merge layer lives entirely in your application code: you fetch the widget skeleton from local storage, fetch the payload from the network, inject the payload into the skeleton, and hand the completed map to Stac.

## Example Workflow

### 1. Store the Widget Skeleton Locally

Save a JSON template with placeholder keys (or empty values) in SQLite, Hive, or even a local JSON file. The template defines the layout but holds no real data:

```json
{
  "type": "scaffold",
  "body": {
    "type": "column",
    "children": [
      {
        "type": "text",
        "data": "{{user_name}}"
      },
      {
        "type": "text",
        "data": "{{account_balance}}"
      },
      {
        "type": "image",
        "data": "{{avatar_url}}"
      }
    ]
  }
}
```


### 2. Fetch Data from the API

Retrieve the live payload independently:

```dart
final response = await http.get(Uri.parse('https://api.example.com/user/123'));
final apiData = jsonDecode(response.body); // e.g. {'user_name': 'Ana', 'account_balance': 'R$ 1.200,00', 'avatar_url': '...'}
```


### 3. Merge Before Rendering

Replace placeholders (or inject values at known paths) and render:

```dart
String templateJson = await localDb.getWidget('user_profile_template');

// Simple placeholder replacement
apiData.forEach((key, value) {
  templateJson = templateJson.replaceAll('{{$key}}', value.toString());
});

final mergedMap = jsonDecode(templateJson);
return Stac.fromJson(mergedMap, context);
```


### 4. Structured Injection (Safer)

Instead of string replacement, store the template as a Dart map and walk the tree:

```dart
Map<String, dynamic> injectData(Map<String, dynamic> template, Map<String, dynamic> data) {
  final cloned = jsonDecode(jsonEncode(template)); // deep copy

  // Traverse and inject at known widget paths
  if (cloned['body']?['type'] == 'column') {
    final children = cloned['body']['children'] as List;
    children[^4_0]['data'] = data['user_name'];
    children[^4_1]['data'] = data['account_balance'];
    children[^4_2]['data'] = data['avatar_url'];
  }
  return cloned;
}

final template = await localDb.getWidgetMap('user_profile');
final merged = injectData(template, apiData);
return Stac.fromJson(merged, context);
```


## Reactive Updates

Stac widgets do not auto-rebuild when external state changes. To refresh after a new API fetch, wrap the render call in a `FutureBuilder` or `StreamBuilder` and trigger a rebuild when the merged JSON changes [^4_3][^4_4].

## Using Stac's Built-in Network Actions

If you want Stac to handle the API call itself (for example, inside a button tap), the framework supports a `networkRequest` action that can reference form field values dynamically [^4_5]. However, that approach fetches data at interaction time within the Stac tree, which is different from pre-merging data before the initial render.

## Offline-First Strategy

For a robust offline-first flow, combine the local template store with a caching layer for the API data. Packages like `offline_first_support` use Hive under the hood and offer policies such as `cacheThenNetwork`, letting you render immediately from local data and refresh silently when the network is available [^4_3][^4_4].

Would you prefer to merge the data by string-template replacement, or by traversing the JSON tree and injecting at specific widget indices?
<span style="display:none">[^4_10][^4_11][^4_12][^4_13][^4_14][^4_15][^4_16][^4_17][^4_6][^4_7][^4_8][^4_9]</span>

<div align="center">⁂</div>

[^4_1]: https://docs.flutter.dev/ai/genui/get-started

[^4_2]: https://www.youtube.com/watch?v=nWr6eZKM6no

[^4_3]: https://pub.dev/packages/offline_first_support

[^4_4]: https://pub.dev/documentation/offline_first_support/latest/

[^4_5]: https://stac.dev/blogs/dynamic-form/

[^4_6]: https://www.youtube.com/watch?v=DGJuBOWl-v0

[^4_7]: https://github.com/StacDev/stac

[^4_8]: https://stackoverflow.com/questions/64649081/how-can-i-make-a-form-with-json-data

[^4_9]: https://pub.dev/documentation/stac/latest/

[^4_10]: https://stackoverflow.com/questions/40302018/jsonschema-dynamic-properties-with-static-properties

[^4_11]: https://stac.mintlify.app/concepts/rendering_stac_widgets

[^4_12]: https://docs.oracle.com/cd/E91846_01/Cloud.12-17/WidgetDev/html/s0314defineawidgetsconfigurablesettin01.html

[^4_13]: https://flutternest.com/blog/flutter-server-driven-ui

[^4_14]: https://github.com/stac-extensions/template/blob/main/json-schema/schema.json

[^4_15]: https://docs.flutter.dev/app-architecture/design-patterns/offline-first

[^4_16]: https://pub.dev/packages/stac/example

[^4_17]: https://experienceleague.adobe.com/en/docs/experience-manager-cloud-service/content/forms/adaptive-forms-authoring/authoring-adaptive-forms-core-components/create-an-adaptive-form-on-forms-cs/adaptive-form-core-components-json-schema-form-model

