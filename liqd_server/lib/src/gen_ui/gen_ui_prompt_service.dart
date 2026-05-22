import 'dart:convert';

import '../generated/protocol.dart';

/// Catalog identifier shared with the Flutter client.
const userCatalogId = 'com.liqd.user_catalog';

/// GenUI basic catalog for native interactive components (Text, Button, …).
const basicCatalogId = 'https://a2ui.org/specification/v0_9/basic_catalog.json';

/// User-catalog component names (seed widgets + custom widgets use these names).
const userCatalogComponentNames = {
  'TextBlock',
  'PrimaryButton',
  'TextFieldInput',
  'VerticalLayout',
  'HorizontalLayout',
  'ScaffoldScreen',
};

/// Builds system prompts for GenUI conversations with catalog context.
abstract final class GenUiPromptService {
  static List<Map<String, String>> fewShotMessages({bool includeEdit = false}) {
    final messages = [
      {
        'role': 'user',
        'content': 'Build a simple counter with a +1 button.',
      },
      {
        'role': 'assistant',
        'content': _counterFewShot,
      },
      {
        'role': 'user',
        'content':
            'Build a todo list with a text field, an Add button, and Delete '
            'on each item.',
      },
      {
        'role': 'assistant',
        'content': _todoFewShot,
      },
    ];

    if (includeEdit) {
      messages.addAll([
        {
          'role': 'user',
          'content': 'Add a Clear button that resets the input field.',
        },
        {
          'role': 'assistant',
          'content': _todoEditFewShot,
        },
      ]);
    }

    return messages;
  }

  static const _counterFewShot =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","justify":"center","align":"center","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"functionCall":{"call":"incrementPath","args":{"path":"/count"},"returnType":"void"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```
''';

  static const _todoFewShot =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/newTodo","value":""}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/todos","value":[]}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["inputRow","todoList"]},{"id":"inputRow","component":"Row","children":["newTodoField","addBtn"]},{"id":"newTodoField","component":"TextField","label":"New todo","value":{"path":"/newTodo"}},{"id":"addBtn","component":"Button","child":"addLabel","action":{"functionCall":{"call":"pushToPath","args":{"path":"/todos","value":{"text":{"path":"/newTodo"},"done":false}},"returnType":"void"}}},{"id":"addLabel","component":"Text","text":"Add"},{"id":"todoList","component":"Column","children":{"path":"/todos","componentId":"todoItem"}},{"id":"todoItem","component":"Row","children":["todoText","deleteBtn"]},{"id":"todoText","component":"Text","text":{"path":"text"}},{"id":"deleteBtn","component":"Button","child":"deleteLabel","action":{"functionCall":{"call":"removeFromPath","args":{"path":"/todos"},"returnType":"void"}}},{"id":"deleteLabel","component":"Text","text":"Delete"}]}}
```
''';

  static const _todoEditFewShot = '''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["inputRow","todoList","clearBtn"]},{"id":"clearBtn","component":"Button","child":"clearLabel","action":{"functionCall":{"call":"setPath","args":{"path":"/newTodo","value":""},"returnType":"void"}}},{"id":"clearLabel","component":"Text","text":"Clear"}]}}
```
''';

  static String buildSystemPrompt(
    List<UserWidget> widgets, {
    bool isEdit = false,
  }) {
    final catalogEntries = widgets
        .map(
          (w) => {
            'name': w.name,
            'description': w.description,
            if (w.dataSchema != null) 'dataSchema': w.dataSchema,
          },
        )
        .toList();

    return '''
You are Liqd, an AI that builds interactive Flutter apps using the A2UI v0.9 protocol.

CRITICAL: Output ONLY valid A2UI JSON blocks in markdown fences. No prose.
${isEdit ? _editModeInstructions : ''}
## Interactive apps (preferred): native GenUI catalog

Use catalogId "$basicCatalogId" with sendDataModel: true.

Emit blocks in order:
1. createSurface — surfaceId, catalogId, sendDataModel: true
2. updateDataModel — initial ephemeral state (paths like /count, /todos, /display)
3. updateComponents — flat components array; one must have id "root"

Native component names (case-sensitive):
$_basicComponentsPrompt

Rules:
- Text "text" may be a literal string OR a binding like {"path":"/count"}.
- TextField "value" binds two-way to a data model path.
- Native Button uses "child" (a component id string), NEVER "label". Put button
  caption text in a separate Text component and reference it from "child".
- User-catalog PrimaryButton uses "label" (string) — only with catalogId
  "$userCatalogId", not with native Button.
- Column, Row, and List "children" may be a string array of component ids OR a
  dynamic template: {"path":"/todos","componentId":"todoItem"}.
- Inside a template row, use relative bindings like {"path":"text"} for fields
  on the current list item (not "/text" unless that is a root data path).
- Every Button MUST use local interactivity via functionCall (NOT event):
  "action": {"functionCall": {"call": "<fn>", "args": {...}, "returnType": "void"}}
- NEVER use action.event for buttons — events are for server-side flows only.
- Every Button MUST set "child" to a component id AND include a matching Text
  component in the same updateComponents array.
- Every id listed in Column/Row/List "children" or Button "child" MUST appear as
  its own component entry in the same updateComponents array.

$_localStateFunctionsPrompt

Counter pattern:
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"functionCall":{"call":"incrementPath","args":{"path":"/count"},"returnType":"void"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```

Numeric entry (e.g. calculator display at /display): use appendToPath for digits
and operators, setPath to clear, evaluateMathPath for equals:
```json
"action":{"functionCall":{"call":"appendToPath","args":{"path":"/display","value":"7"},"returnType":"void"}}
```

## Layout-only / custom Stac widgets

For ScaffoldScreen and user catalog widgets use catalogId "$userCatalogId".
Embed Stac JSON only inside component data fields (body, children).

Stac interactivity (reactive UI):
- Initialize state with a setValue widget wrapping the body:
  {"type":"setValue","values":[{"key":"count","value":0}],"child":{...}}
- Display dynamic values with registry bindings: {"type":"text","data":"{{count}}"}
- Every elevatedButton MUST include onPressed with a setValue action:
  {"type":"setValue","values":[{"key":"count","value":"count+1"}]}
- Use registry key names in expressions (e.g. count+1) for increments.

User catalog widgets:
${_formatUserCatalogEntries(catalogEntries)}
''';
  }

  static const _basicComponentsPrompt = '''
- Column — vertical layout; children: id list or {"path":"…","componentId":"…"}
- Row — horizontal layout; same children rules as Column
- List — scrollable list; same children rules as Column
- Text — display string or {"path":"/key"}; optional variant h1–h5, body, caption
- Button — requires "child" (component id) + "action"; NEVER use "label"
- TextField — two-way "value" binding; variants shortText, longText, number, obscured
- CheckBox — boolean "value" binding; MUST include "label" (string or path)
- Card — grouped content container
- Divider — horizontal separator
- Icon — Material icon by name
- Image — image from url (string or path binding)
- Slider — numeric range input
- Tabs — tabbed navigation
- Modal — bottom sheet overlay
- ChoicePicker — single or multi select from options
- DateTimeInput — date and/or time picker
- AudioPlayer — audio playback with controls
- Video — video playback with controls''';

  static String _formatUserCatalogEntries(
    List<Map<String, Object?>> catalogEntries,
  ) {
    if (catalogEntries.isEmpty) {
      return '- (none)';
    }
    return catalogEntries
        .map((entry) {
          final buffer = StringBuffer(
            '- ${entry['name']}: ${entry['description']}',
          );
          final schema = entry['dataSchema'];
          if (schema != null) {
            buffer.writeln();
            buffer.write('  dataSchema: ${jsonEncode(schema)}');
          }
          return buffer.toString();
        })
        .join('\n');
  }

  static const _localStateFunctionsPrompt = '''
Local client functions (mutate ephemeral data model — no server round-trip):
- setPath — {"path":"/key","value":<any>} sets int, string, object, or array
- incrementPath — {"path":"/count","by":1} (by optional)
- appendToPath — {"path":"/display","value":"7"} (string append or array push)
- togglePath — {"path":"/todos/0/done"}
- pushToPath — {"path":"/todos","value":{...}}
- removeFromPath — {"path":"/todos"} removes current template row; or add "index":0
- evaluateMathPath — {"path":"/display"} for = on arithmetic strings
''';

  static const _editModeInstructions = '''
## Editing an existing app (follow-up requests)

The user already has a live app. You MUST incrementally modify it:
- Reuse the SAME surfaceId from the current app state message.
- Do NOT emit createSurface unless the user explicitly asks for a new screen.
- Prefer updateComponents for changed/new components and updateDataModel for state.
- Only include components you add or change; unchanged components can be omitted.
- When adding buttons or rows, update the parent component's "children" array so new
  components are reachable from "root" (orphan components will not appear in the UI).
- Keep using functionCall for all button actions (never event).
- Never rebuild the entire app from scratch unless the user asks to start over.
- NEVER reply with conversational text, explanations, markdown prose, or summaries.
  The user cannot see chat replies — only A2UI JSON blocks update the app preview.

''';

  /// Formats existing surface JSON for injection as an assistant context message.
  static String? buildExistingSurfacesMessage(String? existingSurfacesJson) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return null;
    }

    return '''
Current app state (preserve surfaceId and incrementally edit):
```json
$existingSurfacesJson
```
''';
  }

  static Set<String> parseExistingSurfaceIds(String? existingSurfacesJson) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(existingSurfacesJson) as Map<String, dynamic>;
      final surfaces = decoded['surfaces'];
      if (surfaces is Map) {
        return surfaces.keys.map((key) => key.toString()).toSet();
      }
    } on FormatException {
      return const {};
    }

    return const {};
  }

  /// Whether an LLM response contains at least one A2UI message type.
  static bool responseContainsA2ui(String response) {
    final lower = response.toLowerCase();
    return lower.contains('updatecomponents') ||
        lower.contains('createsurface') ||
        lower.contains('updatedatamodel') ||
        lower.contains('deletesurface');
  }

  /// Appends edit-mode instructions to the user's follow-up message.
  static String augmentUserMessageForEdit(String content) {
    return '$content\n\n'
        'Apply this to the existing app shown above. '
        'Reply with A2UI ```json blocks only (updateComponents and/or '
        'updateDataModel). No explanatory text.';
  }

  /// Correction prompt when a follow-up returned prose instead of A2UI.
  static String a2uiCorrectionMessage() {
    return 'Your previous reply was plain text. The app preview only updates '
        'from A2UI JSON. Output ONLY ```json blocks with updateComponents '
        'and/or updateDataModel for the existing surfaceId. No prose.';
  }

  static List<Map<String, dynamic>> buildChatMessages({
    required GenUiChatRequest request,
    required bool isEdit,
    required String? existingSurfacesMessage,
    required String systemPrompt,
  }) {
    final userMessages = request.messages;
    return [
      {'role': 'system', 'content': systemPrompt},
      ...fewShotMessages(includeEdit: isEdit),
      if (existingSurfacesMessage != null)
        {'role': 'assistant', 'content': existingSurfacesMessage},
      for (var i = 0; i < userMessages.length; i++)
        {
          'role': userMessages[i].role,
          'content':
              isEdit &&
                  userMessages[i].role == 'user' &&
                  i == userMessages.length - 1
              ? augmentUserMessageForEdit(userMessages[i].content)
              : userMessages[i].content,
        },
    ];
  }
}
