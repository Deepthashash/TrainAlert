import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:train_alert/models/selectedTrainModel.dart';
import 'package:train_alert/models/stationModel.dart';
import 'package:train_alert/models/trainDistanceModel.dart';
import 'package:train_alert/models/trainModel.dart';
import 'package:train_alert/secrets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class FindTrainScreen extends StatefulWidget {
  const FindTrainScreen({key}) : super(key: key);

  @override
  _FindTrainScreenState createState() => _FindTrainScreenState();
}

class _FindTrainScreenState extends State<FindTrainScreen> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController mapController;

  Position _currentPosition;
  String _currentAddress = '';
  StationModel dropdownValue = null;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String _placeDistance;

  Set<Marker> markers = {};

  PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<TrainModel> trains = [];
  List<StationModel> allStations = [];
  List<TrainDistanceModel> sortedStartStations = [];
  List<TrainDistanceModel> sortedEndStations = [];

  List<TrainDistanceModel> finalStations = [];
  List<SelectedTrainModel> finalTrains = [];
  String finalTrainName1 = '';
  String departureTime1 = '';
  String nearestStation1 = '';
  String finalTrainName2 = '';
  String departureTime2 = '';
  String nearestStation2 = '';
  String finalTrainName3 = '';
  String departureTime3 = '';
  String nearestStation3 = '';

  bool isVisble = false;

  Widget _textField({
    TextEditingController controller,
    FocusNode focusNode,
    String label,
    String hint,
    double width,
    Icon prefixIcon,
    Widget suffixIcon,
    Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress = "${place.name}, ${place.locality}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  _getSpecificAddress(end) async {
    try {
      // List<Placemark> p = await placemarkFromCoordinates(
      //     start.latitude, start.longitude);

      // Placemark startLoc = p[0];

      List<Placemark> d = await placemarkFromCoordinates(
          end.latitude, end.longitude);

      Placemark endLoc = d[0];

      setState(() {
        // _startAddress = "${startLoc.name}, ${startLoc.locality}";
        _destinationAddress = "${endLoc.name}, ${endLoc.locality}";
      });
    } catch (e) {
      print(e);
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : startPlacemark[0].latitude;

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Destination Location Marker
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding the markers to the list
      markers.add(startMarker);
      markers.add(destinationMarker);

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

  
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );


      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude, TravelMode.driving);

      double totalDistance = 0.0;

      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
    TravelMode travelMode
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: travelMode,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeStationData();
    _initializeTrainData();
  }

  _initializeTrainData(){
    List<TrainModel> trainData = [];
    FirebaseFirestore.instance
        .collection('Trains')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var model = TrainModel(id:doc["id"],train:doc["train"],origin:doc["origin"],destination:doc["destination"],stations:doc["stations"]);
        trainData.add(model);
      });
      setState(() {
        this.trains = trainData;
      });
    });
  }

  _initializeStationData(){
    List<StationModel> stationData = [];
    FirebaseFirestore.instance
        .collection('Train Stations')
        .orderBy('id')
        .limit(19)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var model = StationModel(id:doc.id,xid:doc["id"],name:doc["name"],timestamp:doc["timestamp"],geo_point:doc["geo_point"]);
        print(model);
        stationData.add(model);
      });
      setState(() {
        this.allStations = stationData;
      });
    });
  }

  _getNearestStartStation() async {
    sortedStartStations = [];
    //get lat and long from current location this is for mock
    List<Location> startPlacemark = await locationFromAddress(_startAddress);
    this.allStations.forEach((element) {
      var distance = _coordinateDistance(startPlacemark[0].latitude, startPlacemark[0].longitude, element.geo_point.latitude, element.geo_point.longitude);
      var time = distance.round() * 3;
      var model = TrainDistanceModel(id: element.id, xid: element.xid, name: element.name, timestamp: element.timestamp, geo_point: element.geo_point, distance: distance, timeDuration: time);
      sortedStartStations.add(model);
    });
    sortedStartStations.sort((a,b) => a.distance.compareTo(b.distance));
    _getFastestTrain();
    // _getSpecificAddress(startPlacemark[0],sortedStartStations[2].geo_point);
    // printTra();
  }

  _getNearestEndStation() async {
    // sortedEndStations = [];
    // //get lat and long from current location this is for mock
    // List<Location> endPlacemark = await locationFromAddress(_destinationAddress);
    // this.allStations.forEach((element) {
    //   var distance = _coordinateDistance(endPlacemark[0].latitude, endPlacemark[0].longitude, element.geo_point.latitude, element.geo_point.longitude);
    //   var time = distance.round() * 3;
    //   var model = TrainDistanceModel(id: element.id, xid: element.xid, name: element.name, timestamp: element.timestamp, geo_point: element.geo_point, distance: distance, timeDuration: time);
    //   sortedEndStations.add(model);
    // });
    // sortedEndStations.sort((a,b) => a.distance.compareTo(b.distance));
    _getNearestStartStation();
  }

  printTra(){
    // allStations.forEach((element) {
    //   print(element.xid);
    // });
    print(this.trains.length.toString() + " no of trains");
  }

  _getFastestTrain() async {
    List<TrainModel> possibleTrains = [];
    List<SelectedTrainModel> mTrains = [];
    var destination = dropdownValue.id;

    print(destination + " destination");

    this.trains.forEach((element) {
      if(element.stations.contains(destination)){
        possibleTrains.add(element);
      }
    });

    print(possibleTrains.length.toString() + "inside");
    if(possibleTrains.isNotEmpty){
      //get all the trains that have this destination
      //filter by (train_timestamp > current timestamp)
      List<SelectedTrainModel> orderedMatchedTrains = [];
      DateTime _now = DateTime.now();
      DateTime _start = DateTime(_now.year, _now.month, _now.day, _now.hour, _now.minute, _now.second);
      int i = 0;
      await Future.forEach(possibleTrains,(element) async {
        i++;
        Map map = new Map<dynamic, dynamic>();
         //query
        await FirebaseFirestore.instance
            .collection('Trains')
            .doc(element.id)
            .collection('Stopping Stations')
            .where('time',isGreaterThan: _start)
            .get()
            .then((QuerySnapshot querySnapshot) {
            querySnapshot.docs.forEach((doc) {
              map.putIfAbsent(doc['stationid'], () => doc['time']);
            });
        }).whenComplete(() => {
          if(map.isNotEmpty){
            mTrains.add(SelectedTrainModel(id:element.id,train: element.train, stations: map))
          }
        });
      });
      if(mTrains.isNotEmpty){
        mTrains.forEach((element) {
          if(!element.stations.containsKey(destination)){
            mTrains.remove(element);
          }
        });
        mTrains.sort((a,b) => a.stations[destination].compareTo(b.stations[destination]));
        if(mTrains.length > 0) {

          for (int i = 0; i < mTrains.length; i++) {
            if (mTrains[i].stations.containsKey(sortedStartStations[0].id)) {
              if (sortedStartStations[0].timeDuration < DateTime
                  .parse(
                  mTrains[i].stations[sortedStartStations[0].id].toDate().toString())
                  .difference(DateTime.now())
                  .inMinutes) {
                finalTrains.add(mTrains[i]);
                finalStations.add(sortedStartStations[0]);
                if(finalTrains.length > 2){
                  break;
                }
              }
            }
            if (mTrains[i].stations.containsKey(sortedStartStations[1].id)) {
              if (sortedStartStations[1].timeDuration < DateTime
                  .parse(
                  mTrains[i].stations[sortedStartStations[1].id].toDate().toString())
                  .difference(DateTime.now())
                  .inMinutes) {
                finalTrains.add(mTrains[i]);
                finalStations.add(sortedStartStations[1]);
                if(finalTrains.length > 2){
                  break;
                }
              }
            }
            if (mTrains[i].stations.containsKey(sortedStartStations[2].id)) {
              if (sortedStartStations[2].timeDuration < DateTime
                  .parse(
                  mTrains[i].stations[sortedStartStations[2].id].toDate().toString())
                  .difference(DateTime.now())
                  .inMinutes) {
                finalTrains.add(mTrains[i]);
                finalStations.add(sortedStartStations[2]);
                if(finalTrains.length > 2){
                  break;
                }
              }
            }
          }
        }
      }
    }

    if(finalStations.length == 0){
      setState(() {
        isVisble = true;
        _clearFields();
      });
    }else{
      setState(() {
        isVisble = false;
        print(finalStations[0].name.toUpperCase());
        finalTrainName1 = finalTrains[0].train.toUpperCase();
        departureTime1 = DateFormat.Hms().format(finalTrains[0].stations[finalStations[0].id].toDate()).toString();
        nearestStation1 = finalStations[0].name.toUpperCase();
      });
      if(finalStations.length > 1){
        setState(() {
          finalTrainName2 = finalTrains[1].train.toUpperCase();
          departureTime2 = DateFormat.Hms().format(finalTrains[1].stations[finalStations[1].id].toDate()).toString();
          nearestStation2 = finalStations[1].name.toUpperCase();
        });
      }
      if(finalStations.length > 2){
        setState(() {
          finalTrainName3 = finalTrains[2].train.toUpperCase();
          departureTime3 = DateFormat.Hms().format(finalTrains[2].stations[finalStations[2].id].toDate()).toString();
          nearestStation3 = finalStations[2].name.toUpperCase();
        });
      }
    }
  }

  _clearFields(){
    isVisble = true;
    finalTrainName1 = '';
    departureTime1 = '';
    nearestStation1 = '';
    finalTrainName2 = '';
    departureTime2 = '';
    nearestStation2 = '';
    finalTrainName3 = '';
    departureTime3 = '';
    nearestStation3 = '';
    finalStations = [];
    finalTrains = [];
  }
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;


    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
       
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Find Fastest Train',
                            style: TextStyle(fontSize: 25.0, fontWeight:FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          // _textField(
                          //     label: 'Start',
                          //     hint: 'Choose starting point',
                          //     prefixIcon: Icon(Icons.looks_one),
                          //     suffixIcon: IconButton(
                          //       icon: Icon(Icons.my_location),
                          //       onPressed: () {
                          //         startAddressController.text = _currentAddress;
                          //         _startAddress = _currentAddress;
                          //       },
                          //     ),
                          //     controller: startAddressController,
                          //     focusNode: startAddressFocusNode,
                          //     width: width,
                          //     locationCallback: (String value) {
                          //       setState(() {
                          //         _startAddress = value;
                          //       });
                          //     }),
                        Container(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all()),
                          child: DropdownButton<StationModel>(
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
                            onChanged: (StationModel newValue) {
                              setState(() {
                                dropdownValue = newValue;
                                _getSpecificAddress(newValue.geo_point);
                              });
                            },
                            items: allStations
                                .map<DropdownMenuItem<StationModel>>((StationModel value) {
                              return DropdownMenuItem<StationModel>(
                                value: value,
                                child: Text(value.name),
                              );
                            }).toList(),
                          ),
                        ),
                          // SizedBox(height: 10),
                          // _textField(
                          //     label: 'Destination',
                          //     hint: 'Choose destination',
                          //     prefixIcon: Icon(Icons.looks_two),
                          //     controller: destinationAddressController,
                          //     focusNode: desrinationAddressFocusNode,
                          //     width: width,
                          //     locationCallback: (String value) {
                          //       setState(() {
                          //         _destinationAddress = value;
                          //       });
                          //     }),
                          SizedBox(height: 10),
                          Visibility(
                            visible: isVisble,
                            child: Text("No Train Found",style: TextStyle(fontSize: 15.0, color: Colors.red),),
                          ),
                          Visibility(
                            visible: finalTrainName1 == '' ? false : true,
                            child: Text("Select the Preferred Train",style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold),),
                          ),
                          SizedBox(height: 5),
                          Visibility(
                            visible: finalTrainName1 == '' ? false : true,
                            child: SizedBox(
                              width: 300,
                              child: Card(
                                child: ListTile(
                                  title: Text(finalTrainName1),
                                  subtitle: Text( nearestStation1 + '\n' + departureTime1),
                                  isThreeLine: true,
                                  trailing: Icon(Icons.open_in_new_outlined),
                                  onTap: () {
                                    MapUtils.openMap(finalStations[0].geo_point.latitude,
                                        finalStations[0].geo_point.longitude);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: finalTrainName2 == '' ? false : true,
                            child: SizedBox(
                              width: 300,
                              child: Card(
                                child: ListTile(
                                  title: Text(finalTrainName2),
                                  subtitle: Text( nearestStation2 + '\n' + departureTime2),
                                  isThreeLine: true,
                                  trailing: Icon(Icons.open_in_new_outlined),
                                  onTap: () {
                                    MapUtils.openMap(finalStations[1].geo_point.latitude,
                                        finalStations[1].geo_point.longitude);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: finalTrainName3 == '' ? false : true,
                            child: SizedBox(
                              width: 300,
                              child: Card(
                                child: ListTile(
                                  title: Text(finalTrainName3),
                                  subtitle: Text( nearestStation3 + '\n' + departureTime3),
                                  isThreeLine: true,
                                  trailing: Icon(Icons.open_in_new_outlined),
                                  onTap: () {
                                    MapUtils.openMap(finalStations[2].geo_point.latitude,
                                        finalStations[2].geo_point.longitude);
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: (_startAddress != '' &&
                                    _destinationAddress != '')
                                ? () async {
                                    print("--------"+_startAddress);
                                    startAddressFocusNode.unfocus();
                                    desrinationAddressFocusNode.unfocus();
                                    setState(() {
                                      _clearFields();
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty)
                                        polylines.clear();
                                      if (polylineCoordinates.isNotEmpty)
                                        polylineCoordinates.clear();
                                      _placeDistance = null;
                                    });
                                    _getNearestEndStation();
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Find Train'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.orange, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapUtils {

  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}