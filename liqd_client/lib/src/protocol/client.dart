/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:liqd_client/src/protocol/apps/user_app.dart' as _i3;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i4;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i5;
import 'package:liqd_client/src/protocol/gen_ui/gen_ui_chat_request.dart'
    as _i6;
import 'package:liqd_client/src/protocol/widgets/user_widget.dart' as _i7;
import 'package:http/http.dart' as _i8;
import 'protocol.dart' as _i9;

/// {@category Endpoint}
class EndpointUserApp extends _i1.EndpointRef {
  EndpointUserApp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'userApp';

  _i2.Future<List<_i3.UserApp>> listApps() =>
      caller.callServerEndpoint<List<_i3.UserApp>>(
        'userApp',
        'listApps',
        {},
      );

  _i2.Future<_i3.UserApp?> getApp(int id) =>
      caller.callServerEndpoint<_i3.UserApp?>(
        'userApp',
        'getApp',
        {'id': id},
      );

  _i2.Future<_i3.UserApp> saveApp({
    int? id,
    required String title,
    required String surfaceStateJson,
  }) => caller.callServerEndpoint<_i3.UserApp>(
    'userApp',
    'saveApp',
    {
      'id': id,
      'title': title,
      'surfaceStateJson': surfaceStateJson,
    },
  );

  _i2.Future<bool> deleteApp(int id) => caller.callServerEndpoint<bool>(
    'userApp',
    'deleteApp',
    {'id': id},
  );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i4.EndpointEmailIdpBase {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<_i5.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i2.Future<_i1.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i2.Future<String> verifyRegistrationCode({
    required _i1.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i2.Future<_i5.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i2.Future<_i1.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i2.Future<String> verifyPasswordResetCode({
    required _i1.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i5.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i5.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointGenUiStream extends _i1.EndpointRef {
  EndpointGenUiStream(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'genUiStream';

  _i2.Stream<String> chatStream(_i6.GenUiChatRequest request) =>
      caller.callStreamingServerEndpoint<_i2.Stream<String>, String>(
        'genUiStream',
        'chatStream',
        {'request': request},
        {},
      );

  _i2.Future<_i7.UserWidget?> generateWidget({
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
  }) => caller.callServerEndpoint<_i7.UserWidget?>(
    'genUiStream',
    'generateWidget',
    {
      'name': name,
      'description': description,
      'dataSchema': dataSchema,
      'stacJson': stacJson,
    },
  );
}

/// {@category Endpoint}
class EndpointWidgetCatalog extends _i1.EndpointRef {
  EndpointWidgetCatalog(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'widgetCatalog';

  _i2.Future<List<_i7.UserWidget>> listMyWidgets() =>
      caller.callServerEndpoint<List<_i7.UserWidget>>(
        'widgetCatalog',
        'listMyWidgets',
        {},
      );

  _i2.Future<_i7.UserWidget> createWidget({
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
  }) => caller.callServerEndpoint<_i7.UserWidget>(
    'widgetCatalog',
    'createWidget',
    {
      'name': name,
      'description': description,
      'dataSchema': dataSchema,
      'stacJson': stacJson,
    },
  );

  _i2.Future<bool> deleteWidget(int id) => caller.callServerEndpoint<bool>(
    'widgetCatalog',
    'deleteWidget',
    {'id': id},
  );

  _i2.Future<void> seedDefaultsForUser() => caller.callServerEndpoint<void>(
    'widgetCatalog',
    'seedDefaultsForUser',
    {},
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i4.Caller(client);
    serverpod_auth_core = _i5.Caller(client);
  }

  late final _i4.Caller serverpod_auth_idp;

  late final _i5.Caller serverpod_auth_core;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i8.Client? httpClientOverride,
  }) : super(
         host,
         _i9.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    userApp = EndpointUserApp(this);
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    genUiStream = EndpointGenUiStream(this);
    widgetCatalog = EndpointWidgetCatalog(this);
    modules = Modules(this);
  }

  late final EndpointUserApp userApp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGenUiStream genUiStream;

  late final EndpointWidgetCatalog widgetCatalog;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'userApp': userApp,
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'genUiStream': genUiStream,
    'widgetCatalog': widgetCatalog,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
