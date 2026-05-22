import 'dart:io';

import 'package:liqd_server/src/stac_app/stac_dev_mock.dart';
import 'package:liqd_server/src/widgets/stac_validator.dart';

/// Quick diagnostic: validate dev mock Stac JSON.
Future<void> main() async {
  for (final entry in [
    ('counter', StacDevMock.counter()),
    ('calculator', StacDevMock.calculator()),
  ]) {
    final result = StacValidator.validate(entry.$2);
    stdout.writeln(
      '${entry.$1}: valid=${result.valid} errors=${result.errors}',
    );
  }
}
