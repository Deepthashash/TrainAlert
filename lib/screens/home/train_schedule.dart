import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TrainSchedule extends StatefulWidget {
  const TrainSchedule({key}) : super(key: key);

  @override
  _TrainScheduleState createState() => _TrainScheduleState();
}

class _TrainScheduleState extends State<TrainSchedule> {
  List<TrainCodePair> trains = [
    new TrainCodePair("Panadura-Maradana Commuter", "Dd"),
    new TrainCodePair("Panadura-Maradana E23", "T2RealTime"),
    new TrainCodePair("Kaluthara-Fort Intercity", "T3RealTime"),
    new TrainCodePair("Kaluthara South - Fort E01", "T4RealTime")
  ];
  TrainCodePair dropdownValue;

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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Text(
                  "Select the train",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all()),
            child: DropdownButton<TrainCodePair>(
              value: dropdownValue,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              isExpanded: false,
              hint: Text('Select End Station'),
              // style: const TextStyle(color: Colors.deepPurple),
              // underline: Container(
              //   height: 2,
              //   color: Colors.deepPurpleAccent,
              // ),
              onChanged: (TrainCodePair newValue) {
                setState(() {
                  dropdownValue = newValue;
                  // _getSpecificAddress(newValue.geo_point);
                });
              },
              items: trains
                  .map<DropdownMenuItem<TrainCodePair>>((TrainCodePair value) {
                return DropdownMenuItem<TrainCodePair>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: StreamBuilder(
                  stream:
                      FirebaseFirestore.instance.collection(dropdownValue._code).snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: snapshot.data.docChanges.map((document) {
                        return Card(
                          child: ListTile(
                            isThreeLine: true,
                            leading: Icon(Icons.train),
                            title: Text(document.doc["Station"]),
                            subtitle: Text("Arrival Time: " +
                                DateTime.fromMillisecondsSinceEpoch(
                                        document.doc["time"])
                                    .hour
                                    .toString() +
                                ":" +
                                DateTime.fromMillisecondsSinceEpoch(
                                        document.doc["time"])
                                    .minute
                                    .toString() +
                                "\n" +
                                "Departure Time: " +
                                DateTime.fromMillisecondsSinceEpoch(
                                        document.doc["time"])
                                    .hour
                                    .toString() +
                                ":" +
                                DateTime.fromMillisecondsSinceEpoch(
                                        document.doc["time"])
                                    .minute
                                    .toString()),
                          ),
                        );
                      }).toList(),
                    );
                  }),
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    dropdownValue = trains[0];
  }


}

class TrainCodePair {
  String _name;
  String _code;

  TrainCodePair(this._name, this._code);

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  String get code => _code;

  set code(String value) {
    _code = value;
  }
}
