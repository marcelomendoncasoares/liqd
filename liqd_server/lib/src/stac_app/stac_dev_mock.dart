/// Canned Stac JSON for local development when OpenRouter is unavailable.
abstract final class StacDevMock {
  static Map<String, dynamic> counter() => {
    'type': 'setValue',
    'values': [
      {'key': 'count', 'value': 0},
    ],
    'child': {
      'type': 'column',
      'mainAxisAlignment': 'center',
      'crossAxisAlignment': 'center',
      'children': [
        {
          'type': 'text',
          'data': '{{count}}',
          'style': {'fontSize': 48},
        },
        {
          'type': 'elevatedButton',
          'child': {'type': 'text', 'data': '+1'},
          'onPressed': {
            'actionType': 'setValue',
            'values': [
              {'key': 'count', 'value': '{{count}} + 1'},
            ],
          },
        },
      ],
    },
  };

  static Map<String, dynamic> calculator() => {
    'type': 'setValue',
    'values': [
      {'key': 'display', 'value': '0'},
    ],
    'child': {
      'type': 'column',
      'mainAxisAlignment': 'center',
      'crossAxisAlignment': 'stretch',
      'children': [
        {
          'type': 'text',
          'data': '{{display}}',
          'style': {'fontSize': 32},
        },
        {
          'type': 'row',
          'mainAxisAlignment': 'center',
          'children': [
            _digitButton('7'),
            _digitButton('8'),
            _digitButton('9'),
          ],
        },
        {
          'type': 'row',
          'mainAxisAlignment': 'center',
          'children': [
            _operatorButton('+'),
            _operatorButton('-'),
            _clearButton(),
          ],
        },
        {
          'type': 'row',
          'mainAxisAlignment': 'center',
          'children': [
            _equalsButton(),
          ],
        },
      ],
    },
  };

  static Map<String, dynamic> _digitButton(String digit) => {
    'type': 'elevatedButton',
    'child': {'type': 'text', 'data': digit},
    'onPressed': {
      'actionType': 'setValue',
      'values': [
        {'key': 'display', 'value': '{{display}}$digit'},
      ],
    },
  };

  static Map<String, dynamic> _operatorButton(String operator) => {
    'type': 'elevatedButton',
    'child': {'type': 'text', 'data': operator},
    'onPressed': {
      'actionType': 'setValue',
      'values': [
        {'key': 'display', 'value': '{{display}}$operator'},
      ],
    },
  };

  static Map<String, dynamic> _clearButton() => {
    'type': 'elevatedButton',
    'child': {'type': 'text', 'data': 'C'},
    'onPressed': {
      'actionType': 'setValue',
      'values': [
        {'key': 'display', 'value': '0'},
      ],
    },
  };

  static Map<String, dynamic> _equalsButton() => {
    'type': 'filledButton',
    'child': {'type': 'text', 'data': '='},
    'onPressed': {
      'actionType': 'setValue',
      'values': [
        {'key': 'display', 'value': '{{display}}'},
      ],
    },
  };
}
