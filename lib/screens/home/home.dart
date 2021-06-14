import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:train_alert/screens/home/find_train_screen.dart';
import 'package:train_alert/services/authService.dart';

class Home extends StatelessWidget {
  final AuthService _authService = AuthService();
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
              await _authService.signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Container(
                  // width: 90,
                  height: 250,
                  decoration: BoxDecoration(
                      // shape: BoxShape.circle,
                      image: DecorationImage(
                          image: AssetImage('assets/images/station.jpg'),
                          fit: BoxFit.fill))),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          (MaterialPageRoute(
                              builder: (context) => FindTrainScreen())));
                    },
                    child: CustomCard(
                      title: "Find train",
                      subTitle: 'Find best train nearby',
                      image: 'assets/images/findTrain.jpg',
                      direction: "left",
                    ),
                  )),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {},
                    child: CustomCard(
                      title: "View Trains",
                      subTitle: 'View trains and their status',
                      image: 'assets/images/viewTrain.jpg',
                      direction: "right",
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () => print("hello"),
                    child: CustomCard(
                      title: "Train Schedule",
                      subTitle: 'Find Trains by time and date',
                      image: 'assets/images/schedule.jpg',
                      direction: "left",
                    ),
                  )),
                  Expanded(
                      child: GestureDetector(
                    onTap: () => print("hello"),
                    child: CustomCard(
                      title: "Profile",
                      subTitle: 'View/Update profile',
                      image: 'assets/images/profile.jpg',
                      direction: "right",
                    ),
                  )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String direction;
  final String image;

  CustomCard(
      {@required this.title,
      @required this.subTitle,
      @required this.direction,
      @required this.image})
      : assert(title != null &&
            direction != null &&
            subTitle != null &&
            image != null);

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: (direction == 'left')
          ? EdgeInsets.only(bottom: 10.0, left: 40.0, right: 10.0, top: 10.0)
          : EdgeInsets.only(bottom: 10.0, left: 10.0, right: 40.0, top: 10.0),
      height: 200.0,
      child: Card(
        child: Column(
          children: [
            Container(
                margin: EdgeInsets.only(top: 15.0),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: AssetImage(image), fit: BoxFit.fill))),
            SizedBox(
              height: 5.0,
            ),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(
              height: 3.0,
              thickness: 2.0,
            ),
            Container(
              margin: EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0),
              child: Text(
                subTitle,
                style: TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
