import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/chat/gen_ui_update_outcome.dart';
import 'package:liqd_flutter/features/chat/ui_interaction.dart';

void main() {
  group('Given a completed GenUI model stream,', () {
    test(
      'when the response is prose only, '
      'then the outcome reports no A2UI was applied.',
      () {
        final outcome = GenUiUpdateOutcome.evaluate(
          rawResponse: 'Sure, I can help with that.',
          parsedMessageCount: 0,
          parsedMessageTypes: const [],
          surfaceUpdated: false,
          wasCancelled: false,
        );

        expect(outcome.kind, GenUiUpdateOutcomeKind.noA2ui);
        expect(outcome.isWarning, isTrue);
        expect(outcome.detail, 'Sure, I can help with that.');
      },
    );

    test(
      'when the response mentions A2UI but nothing parses, '
      'then the outcome reports unparsed UI data.',
      () {
        final outcome = GenUiUpdateOutcome.evaluate(
          rawResponse: '{"updateComponents": broken',
          parsedMessageCount: 0,
          parsedMessageTypes: const [],
          surfaceUpdated: false,
          wasCancelled: false,
        );

        expect(outcome.kind, GenUiUpdateOutcomeKind.unparsedA2ui);
        expect(outcome.isWarning, isTrue);
      },
    );

    test(
      'when A2UI parses but the preview does not change, '
      'then the outcome reports the update was not applied.',
      () {
        final outcome = GenUiUpdateOutcome.evaluate(
          rawResponse: '{"updateComponents": {"surfaceId": "main"}}',
          parsedMessageCount: 1,
          parsedMessageTypes: const ['UpdateComponents'],
          surfaceUpdated: false,
          wasCancelled: false,
        );

        expect(outcome.kind, GenUiUpdateOutcomeKind.notApplied);
        expect(outcome.isWarning, isTrue);
      },
    );

    test(
      'when only the data model updates, '
      'then the outcome is treated as applied.',
      () {
        final outcome = GenUiUpdateOutcome.evaluate(
          rawResponse: '{"updateDataModel": {"surfaceId": "main"}}',
          parsedMessageCount: 1,
          parsedMessageTypes: const ['UpdateDataModel'],
          surfaceUpdated: false,
          wasCancelled: false,
        );

        expect(outcome.kind, GenUiUpdateOutcomeKind.applied);
        expect(outcome.isWarning, isFalse);
      },
    );

    test(
      'when the surface updates, '
      'then the outcome is treated as applied.',
      () {
        final outcome = GenUiUpdateOutcome.evaluate(
          rawResponse: '{"updateComponents": {"surfaceId": "main"}}',
          parsedMessageCount: 1,
          parsedMessageTypes: const ['UpdateComponents'],
          surfaceUpdated: true,
          wasCancelled: false,
        );

        expect(outcome.kind, GenUiUpdateOutcomeKind.applied);
        expect(outcome.isWarning, isFalse);
      },
    );
  });

  group('Given a GenUI validation error envelope,', () {
    test(
      'when it arrives on the submit stream, '
      'then the feedback message and location are parsed.',
      () {
        final message = ChatMessage.user(
          '',
          parts: [
            UiInteractionPart.create(
              '{"version":"v0.9","error":{"code":"VALIDATION_FAILED",'
              '"surfaceId":"main","path":"/todos","message":"Invalid binding"}}',
            ),
          ],
        );

        final feedback = UiInteraction.parseErrorFeedback(message);

        expect(feedback, isNotNull);
        expect(feedback!.code, 'VALIDATION_FAILED');
        expect(feedback.surfaceId, 'main');
        expect(feedback.path, '/todos');
        expect(feedback.message, 'Invalid binding');
      },
    );
  });
}
