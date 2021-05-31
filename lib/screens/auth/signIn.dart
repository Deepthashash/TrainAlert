import 'package:flutter/material.dart';
import 'package:train_alert/services/authService.dart';
import 'package:flutter/gestures.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  String _email;
  String _password;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
            margin: EdgeInsets.only(top: 200.0, left: 20.0, right: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                          width: 250.0,
                          child: Text(
                            "Smart Train Finder",
                            style: TextStyle(
                                fontSize: 30.0, fontWeight: FontWeight.bold),
                          )),
                      Expanded(
                        child:
                            Image(image: AssetImage('assets/images/logo.jpg')),
                      )
                    ],
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
                          return 'Please enter some text';
                        }else if(!value.contains("@")){
                          return 'Please enter an email address';
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
                        var results = await _authService
                            .signInUsingEmailAndPassword(_email, _password);
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
                                  print('Terms of Service"');
                                })
                        ]),
                      )),
                ],
              ),
            )),
      ),
    );
  }
}
