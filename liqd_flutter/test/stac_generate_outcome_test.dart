import 'package:liqd_flutter/features/stac_app/stac_generate_outcome.dart';
import 'package:test/test.dart';

void main() {
  group('StacGenerateOutcome', () {
    test('applied when stacJson is present', () {
      final outcome = StacGenerateOutcome.evaluate(
        stacJson: {'type': 'text', 'data': 'Hi'},
        validationErrors: null,
        rawResponse: 'ok',
      );

      expect(outcome.kind, StacGenerateOutcomeKind.applied);
      expect(outcome.isWarning, isFalse);
    });

    test('validationFailed when errors are returned', () {
      final outcome = StacGenerateOutcome.evaluate(
        stacJson: null,
        validationErrors: const ['Missing type field.'],
        rawResponse: 'bad',
      );

      expect(outcome.kind, StacGenerateOutcomeKind.validationFailed);
      expect(outcome.isWarning, isTrue);
    });

    test('noStac when response has no JSON', () {
      final outcome = StacGenerateOutcome.evaluate(
        stacJson: null,
        validationErrors: null,
        rawResponse: 'Sure, I can help with that.',
      );

      expect(outcome.kind, StacGenerateOutcomeKind.noStac);
      expect(outcome.detail, contains('Sure'));
    });
  });
}
