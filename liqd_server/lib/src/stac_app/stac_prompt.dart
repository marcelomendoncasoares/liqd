import '../widgets/stac_validator.dart';

/// Builds OpenRouter chat messages for Stac app generation.
abstract final class StacPrompt {
  static const counterFewShotAssistant = '''
```json
{
  "type": "setValue",
  "values": [{"key": "count", "value": 0}],
  "child": {
    "type": "column",
    "mainAxisAlignment": "center",
    "crossAxisAlignment": "center",
    "children": [
      {
        "type": "text",
        "data": "{{count}}",
        "style": {"fontSize": 48}
      },
      {
        "type": "elevatedButton",
        "child": {"type": "text", "data": "+1"},
        "onPressed": {
          "actionType": "setValue",
          "values": [{"key": "count", "value": "{{count}} + 1"}]
        }
      }
    ]
  }
}
```
''';

  static List<Map<String, String>> fewShotMessages() => [
    {'role': 'user', 'content': 'Build a simple counter with a +1 button.'},
    {'role': 'assistant', 'content': counterFewShotAssistant},
  ];

  static String buildSystemPrompt({required bool isEdit}) {
    final allowedTypes = StacValidator.allowedTypes.join(', ');
    final buffer = StringBuffer('''
You are Liqd, an AI that builds interactive Flutter apps as Stac JSON widget trees.

CRITICAL: Output ONLY one valid Stac JSON object inside a ```json fenced block. No prose.

Allowed widget types: $allowedTypes

Interactive apps MUST use a root "setValue" widget to initialize registry keys, then
reference them with {{key}} placeholders in text data or button values.

Button actions use onPressed with actionType "setValue":
```json
"onPressed": {
  "actionType": "setValue",
  "values": [{"key": "display", "value": "{{display}}7"}]
}
```

Use "{{count}} + 1" in setValue values for numeric increment.
Use "{{display}}" alone as the value to evaluate basic +−*/ arithmetic on the current display string.
''');

    if (isEdit) {
      buffer.writeln('''
When editing an existing app, output the COMPLETE updated Stac JSON tree.
Do not explain changes — only the fenced JSON block.
''');
    } else {
      buffer.writeln('''
For new apps, wrap the UI in a root setValue widget that initializes all state keys.
The tree must include a "type" field at the root.

NEVER use "scaffold" or "appBar". The preview pane already provides screen chrome.
Use "column", "row", "card", and "padding" for layout instead.
''');
    }

    return buffer.toString().trim();
  }

  static String? buildExistingStacMessage(String? existingStacJson) {
    if (existingStacJson == null || existingStacJson.trim().isEmpty) {
      return null;
    }

    return '''
Current app Stac JSON (output the full updated tree):
```json
$existingStacJson
```
''';
  }

  static List<Map<String, String>> buildChatMessages({
    required bool isEdit,
    required String? existingStacMessage,
    required List<Map<String, String>> userMessages,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': buildSystemPrompt(isEdit: isEdit)},
      ...fewShotMessages(),
    ];

    if (existingStacMessage != null) {
      messages.add({'role': 'user', 'content': existingStacMessage});
    }

    messages.addAll(userMessages);
    return messages;
  }

  static String validationRetryMessage(List<String> errors) {
    return '''
The Stac JSON was invalid:
${errors.map((error) => '- $error').join('\n')}

Reply with a corrected complete Stac JSON object in a single ```json block only.
''';
  }

  static String stacCorrectionMessage() {
    return '''
Your reply did not contain valid Stac JSON with a root "type" field.
Reply with one complete Stac JSON object in a ```json fenced block only. No prose.
''';
  }
}
