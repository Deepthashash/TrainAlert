import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({key}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Train Alert"),
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
            label: Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              // await _authService.signOut();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                "User Profile",
                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
              )),
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: Image.asset(
                  'assets/images/default_prof.jpg',
                  height: 150.0,
                  width: 150.0,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30.0,
          ),
          Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Name: ",
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Nilanga De Silva",
                      style: TextStyle(fontSize: 24.0),
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5.0,
          ),
          Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Card(

              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Email: ",
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "hello57@gmail.com",
                      style: TextStyle(fontSize: 24.0),
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5.0,
          ),
          Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Address: ",
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "No.16,"
                          +"\n"
                      +"6th Lane,"
                      +"\n"
                      +"Colombo 05",
                      style: TextStyle(fontSize: 24.0),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
