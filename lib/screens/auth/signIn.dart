import 'package:flutter/material.dart';
import 'package:train_alert/services/authService.dart';
import 'package:flutter/gestures.dart';
import 'package:train_alert/screens/auth/signUp.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  String _email;
  String _password;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: loading ? CircularProgressIndicator() : Container(
              margin: EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      child:
                          Image(image: AssetImage('assets/images/logo.jpg')),
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(primaryColor: Colors.cyan),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Email",
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Field cannot be empty!';
                          }else if(!value.contains("@")){
                            return 'Please enter an email address!';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _email = val;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(primaryColor: Colors.cyan),
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                        ),
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Field cannot be empty!';
                          }else if(value.length < 6){
                            return 'Should be at least 6 figures long!';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _password = val;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    Container(
                      padding: EdgeInsets.only(left: 230.0),
                        child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                            text: 'Forgot Password?',
                            style: TextStyle(color: Colors.cyan),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                print('Terms of Service"');
                              })
                      ]),
                    )),
                    SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.cyan,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(100.0)),
                          ),
                          minimumSize: Size(200, 60)),
                      child: Text("Login",
                      style: TextStyle(fontSize: 20.0),),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          setState(() {
                            loading = true;
                          });
                          var results = null;
                          results = await _authService
                              .signInUsingEmailAndPassword(_email, _password);
                          if(results == null){
                            setState(() {
                              loading = false;
                            });
                            _showMyDialog();
                            //error message
                          }
                        }
                      },
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    Container(
                        child: RichText(
                          text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'New user? Register here',
                                style: TextStyle(color: Colors.cyan,fontSize: 20.0,fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignUp()),
                                  );
                                  })
                          ]),
                        )),
                  ],
                ),
              )),
        ),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wrong Credentials!'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
