import 'package:flutter/material.dart';
import 'package:train_alert/services/authService.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            child: Text("Log In"), onPressed: () async {
             await authService.signInUsingEmailAndPassword();
        }),
      ),
    );
  }
}
