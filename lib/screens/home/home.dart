import 'package:flutter/material.dart';
import 'package:train_alert/services/authService.dart';

class Home extends StatelessWidget{
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Train Alert"),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.person, color: Colors.white,),
            label: Text("Logout",style: TextStyle(color: Colors.white),),
            onPressed: () async {
              await _authService.signOut();
            },
          )
        ],
      ),
    );
  }
}