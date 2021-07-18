import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:train_alert/screens/auth/auth.dart';
import 'package:train_alert/models/userModel.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserModel>(context);
    print(user);

    // return either the Home or Authenticate widget
    if (user == null){
      return Auth();
    } else {
      return Home();
    }
  }
}