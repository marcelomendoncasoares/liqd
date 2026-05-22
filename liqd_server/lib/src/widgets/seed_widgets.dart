import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Default Stac widget templates seeded for new users.
abstract final class SeedWidgets {
  static List<UserWidget> defaults({required UuidValue authUserId}) {
    return [
      UserWidget(
        authUserId: authUserId,
        name: 'TextBlock',
        description:
            'Displays a block of text. Use for headings, labels, or paragraphs.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'text': {'type': 'string', 'description': 'The text to display.'},
          },
          'required': ['text'],
        },
        stacJson: {
          'type': 'text',
          'data': '{{text}}',
          'style': {'fontSize': 16},
        },
        isSeed: true,
      ),
      UserWidget(
        authUserId: authUserId,
        name: 'PrimaryButton',
        description: 'A filled button with a label.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Button label text.',
            },
          },
          'required': ['label'],
        },
        stacJson: {
          'type': 'elevatedButton',
          'child': {
            'type': 'text',
            'data': '{{label}}',
          },
        },
        isSeed: true,
      ),
      UserWidget(
        authUserId: authUserId,
        name: 'TextFieldInput',
        description: 'A text input field with a label.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Input field label.',
            },
            'hint': {
              'type': 'string',
              'description': 'Placeholder hint text.',
            },
          },
          'required': ['label'],
        },
        stacJson: {
          'type': 'textField',
          'decoration': {
            'labelText': '{{label}}',
            'hintText': '{{hint}}',
          },
        },
        isSeed: true,
      ),
      UserWidget(
        authUserId: authUserId,
        name: 'VerticalLayout',
        description:
            'Arranges child widgets vertically in a column with spacing.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'children': {
              'type': 'array',
              'description':
                  'List of Stac JSON widget objects to display vertically.',
              'items': {'type': 'object'},
            },
            'spacing': {
              'type': 'number',
              'description': 'Vertical spacing between children.',
            },
          },
          'required': ['children'],
        },
        stacJson: {
          'type': 'column',
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'stretch',
          'children': '{{children}}',
        },
        isSeed: true,
      ),
      UserWidget(
        authUserId: authUserId,
        name: 'HorizontalLayout',
        description: 'Arranges child widgets horizontally in a row.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'children': {
              'type': 'array',
              'description':
                  'List of Stac JSON widget objects to display horizontally.',
              'items': {'type': 'object'},
            },
          },
          'required': ['children'],
        },
        stacJson: {
          'type': 'row',
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'center',
          'children': '{{children}}',
        },
        isSeed: true,
      ),
      UserWidget(
        authUserId: authUserId,
        name: 'ScaffoldScreen',
        description:
            'A full screen scaffold with an optional app bar title and body content.',
        dataSchema: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'App bar title.',
            },
            'body': {
              'type': 'object',
              'description': 'Stac JSON widget for the body content.',
            },
          },
          'required': ['body'],
        },
        stacJson: {
          'type': 'scaffold',
          'appBar': {
            'type': 'appBar',
            'title': {
              'type': 'text',
              'data': '{{title}}',
            },
          },
          'body': '{{body}}',
        },
        isSeed: true,
      ),
    ];
  }
}
