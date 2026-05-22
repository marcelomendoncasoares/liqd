import 'package:flutter/material.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.client,
    required this.child,
  });

  final Client client;
  final Widget child;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    widget.client.auth.authInfoListenable.addListener(_updateSignedInState);
    _isSignedIn = widget.client.auth.isAuthenticated;
    if (_isSignedIn) {
      _seedCatalog();
    }
  }

  @override
  void dispose() {
    widget.client.auth.authInfoListenable.removeListener(_updateSignedInState);
    super.dispose();
  }

  void _updateSignedInState() {
    final signedIn = widget.client.auth.isAuthenticated;
    setState(() {
      _isSignedIn = signedIn;
    });
    if (signedIn) {
      _seedCatalog();
    }
  }

  Future<void> _seedCatalog() async {
    try {
      await widget.client.widgetCatalog.seedDefaultsForUser();
    } on Object {
      // Seeding is best-effort; catalog loads on first builder open.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isSignedIn
        ? widget.child
        : Scaffold(
            body: Center(
              child: SignInWidget(
                client: widget.client,
                onAuthenticated: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed in'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Authentication failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          );
  }
}
