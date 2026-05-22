import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Resolves the OpenRouter API key from Serverpod passwords or environment.
abstract final class OpenRouterConfig {
  static const passwordKey = 'openRouterApiKey';
  static const envVarName = 'OPENROUTER_API_KEY';

  static String? resolveApiKey(Session session) {
    final fromPasswords = session.passwords[passwordKey];
    if (fromPasswords != null && fromPasswords.trim().isNotEmpty) {
      return fromPasswords.trim();
    }

    for (final key in [envVarName, 'SERVERPOD_PASSWORD_$passwordKey']) {
      final fromEnv = Platform.environment[key];
      if (fromEnv != null && fromEnv.trim().isNotEmpty) {
        return fromEnv.trim();
      }
    }

    return null;
  }

  static String missingKeyMessage() =>
      'OpenRouter API key is not configured. Set '
      '$passwordKey in config/passwords.yaml, export $envVarName, or set '
      'SERVERPOD_PASSWORD_$passwordKey when starting the server.';
}
