import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:train_alert/models/userModel.dart';

class AuthService {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //create user object
  UserModel _getuser(User user) {
    return user != null ? UserModel(uid: user.uid,email: user.email): null;
  }

  //listening to auth changes
  Stream<UserModel> get user {
    return _firebaseAuth.authStateChanges().map(_getuser);
  }

  //sign in using email and password
  Future signInUsingEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      User user = result.user;
      return _getuser(user);
    }catch(e){
      print(e.toString());
      return null;
    }
  }

  //sign up using email and password
  Future signUpUsingEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      User user = result.user;
      return _getuser(user);
    }catch(e){
      print(e.toString());
      return null;
    }
  }

  //google sign in
  Future googleSignIn() async{
    try{
      // UserCredential result = await _firebaseAuth.sign
    }catch(e){
      print(e.toString());
      return null;
    }
  }

  //sign out
  Future signOut() async{
    try{
      return await _firebaseAuth.signOut();
    }catch(e){
      print(e.toString());
      return null;
    }
  }
}