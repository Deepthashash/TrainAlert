import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:train_alert/cache/TrainData.dart';
import 'package:train_alert/models/selectedTrainModel.dart';
import 'package:train_alert/models/stationModel.dart';
import 'package:train_alert/models/trainModel.dart';
import 'package:train_alert/secrets.dart';
import 'package:train_alert/services/trainService.dart';

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
  List<String> stations = ['04uqieJGZVboaeRp6YeK','07UvGGQfxc48jpVUih50','0sb1nE7HwgHAhvtx7vwW','1Zu4AlX7z04acTWreujR'];

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
          destinationLongitude, TravelMode.transit);

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
    _initializeStationData();
    _initializeTrainData();
    _getCurrentLocation();
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
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var model = StationModel(id:doc.id,name:doc["name"],timestamp:doc["timestamp"],geo_point:doc["geo_point"]);
        print(model);
        stationData.add(model);
      });
      setState(() {
        this.allStations = stationData;
      });
    });
  }

  _getFastestTrain() async {
    List<TrainModel> possibleTrains = [];
    var origin = "07UvGGQfxc48jpVUih50";
    var destination = "1Zu4AlX7z04acTWreujR";
    List<SelectedTrainModel> mTrains = [];
    print(this.allStations.length.toString() + " station size");

    this.trains.forEach((element) {
      if(element.stations.contains(destination)){
        possibleTrains.add(element);
      }
    });

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
            // .where('stationid',isEqualTo: destination )
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
      //get the lowest timestamp
      List<SelectedTrainModel> orderedByTimeStamp = [];
      mTrains.forEach((element) {
        if(!element.stations.containsKey(destination)){
          mTrains.remove(element);
        }
      });
      mTrains.sort((a,b) => a.stations[destination].compareTo(b.stations[destination]));

      SelectedTrainModel finalTrain = null;
      SelectedTrainModel originTrain = null;
      StationModel startStation = null;
      int endIndex = mTrains.length;

      if(mTrains.length > 0){
        for(int i=0; i < mTrains.length; i++ ) {
          if (mTrains[i].stations.containsKey(origin)) {
            originTrain = mTrains[i];
            endIndex = i;
            if(endIndex==0){
              finalTrain = originTrain;
              startStation = allStations.firstWhere((element) =>
              element.id == origin,
                  orElse: () {
                    return null;
                  });
            }
            break;
          }
        }

        if(finalTrain == null){
          if(originTrain != null){
            var current = stations.indexOf(origin);
            var nextStation = stations[current+1];
            var prevStation = stations[current-1];
            for(int i=0; i < endIndex; i++ ) {
              if(mTrains[i].stations.containsKey(prevStation) && mTrains[i].stations.containsKey(nextStation)){
                int prevTime = null;
                int nextTime = null;
                if(nextStation != destination){
                  var nextStationData = allStations.firstWhere((element) =>
                  element.id == nextStation,
                  orElse: () {
                    return null;
                  });
                  var nextStationCordinate = nextStationData.geo_point;
                  var originStationData =  allStations.firstWhere((element) =>
                  element.id == origin,
                      orElse: () {
                        return null;
                      });
                  var originStationCordinate = originStationData.geo_point;
                  nextTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, nextStationCordinate.latitude, nextStationCordinate.longitude).round() * 3;
                  print(nextTime.toString() + " nextllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
                }
                //get prev time
                var prevStationData = allStations.firstWhere((element) =>
                element.id == prevStation,
                    orElse: () {
                      return null;
                    });
                var prevStationCordinate = prevStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                prevTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, prevStationCordinate.latitude, prevStationCordinate.longitude).round() * 3;
                print(prevTime.toString() + " prevllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
                if(nextTime != null && (nextTime < prevTime)){
                  //check for ability to arrive in time
                  print(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString()).difference(DateTime.now()).inMinutes.toString() + "fuck meeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
                  if(nextTime < DateTime.parse(mTrains[i].stations[nextStation].toDate().toString()).difference(DateTime.now()).inMinutes){
                    print("hi sexyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == nextStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }
                  //else cannot catch the train
                  continue;
                }else{
                  //check for ability to arrive in time
                  if(prevTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[prevStation].toDate().toString())).inMinutes){
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == prevStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }else if(nextTime != null && nextTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString())).inMinutes) {
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == nextStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }
                }

              }else if(mTrains[i].stations.containsKey(prevStation)){
                int prevTime = null;
                var prevStationData = allStations.firstWhere((element) =>
                element.id == prevStation,
                    orElse: () {
                      return null;
                    });
                var prevStationCordinate = prevStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                prevTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, prevStationCordinate.latitude, prevStationCordinate.longitude).round() * 3;
                if(prevTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[prevStation].toDate().toString())).inMinutes){
                  finalTrain = mTrains[i];
                  startStation = prevStationData;
                  break;
                }
              } else if(mTrains[i].stations.containsKey(nextStation)){
                int nextTime = null;
                var nextStationData = allStations.firstWhere((element) =>
                element.id == nextStation,
                    orElse: () {
                      return null;
                    });
                var nextStationCordinate = nextStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                nextTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, nextStationCordinate.latitude, nextStationCordinate.longitude).round() * 3;
                if(nextTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString())).inMinutes){
                  finalTrain = mTrains[i];
                  startStation = nextStationData;
                  break;
                }
              }
            }
          }else{
            var current = stations.indexOf(origin);
            var nextStation = stations[current+1];
            var prevStation = stations[current-1];
            for(int i=0; i < endIndex; i++ ) {
              if(mTrains[i].stations.containsKey(prevStation) && mTrains[i].stations.containsKey(nextStation)){
                int prevTime = null;
                int nextTime = null;
                if(nextStation != destination){
                  var nextStationData = allStations.firstWhere((element) =>
                  element.id == nextStation,
                      orElse: () {
                        return null;
                      });
                  var nextStationCordinate = nextStationData.geo_point;
                  var originStationData =  allStations.firstWhere((element) =>
                  element.id == origin,
                      orElse: () {
                        return null;
                      });
                  var originStationCordinate = originStationData.geo_point;
                  nextTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, nextStationCordinate.latitude, nextStationCordinate.longitude).round() * 3;
                  print(nextTime.toString() + " nextllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
                }
                //get prev time
                var prevStationData = allStations.firstWhere((element) =>
                element.id == prevStation,
                    orElse: () {
                      return null;
                    });
                var prevStationCordinate = prevStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                prevTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, prevStationCordinate.latitude, prevStationCordinate.longitude).round() * 3;
                print(prevTime.toString() + " prevllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
                if(nextTime != null && (nextTime < prevTime)){
                  //check for ability to arrive in time
                  print(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString()).difference(DateTime.now()).inMinutes.toString() + "fuck meeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
                  if(nextTime < DateTime.parse(mTrains[i].stations[nextStation].toDate().toString()).difference(DateTime.now()).inMinutes){
                    print("hi sexyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == nextStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }
                  //else cannot catch the train
                  continue;
                }else{
                  //check for ability to arrive in time
                  if(prevTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[prevStation].toDate().toString())).inMinutes){
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == prevStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }else if(nextTime != null && nextTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString())).inMinutes) {
                    finalTrain = mTrains[i];
                    startStation = allStations.firstWhere((element) =>
                    element.id == nextStation,
                        orElse: () {
                          return null;
                        });
                    break;
                  }
                }

              }else if(mTrains[i].stations.containsKey(prevStation)){
                int prevTime = null;
                var prevStationData = allStations.firstWhere((element) =>
                element.id == prevStation,
                    orElse: () {
                      return null;
                    });
                var prevStationCordinate = prevStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                prevTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, prevStationCordinate.latitude, prevStationCordinate.longitude).round() * 3;
                if(prevTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[prevStation].toDate().toString())).inMinutes){
                  finalTrain = mTrains[i];
                  startStation = prevStationData;
                  break;
                }
              } else if(mTrains[i].stations.containsKey(nextStation)){
                int nextTime = null;
                var nextStationData = allStations.firstWhere((element) =>
                element.id == nextStation,
                    orElse: () {
                      return null;
                    });
                var nextStationCordinate = nextStationData.geo_point;
                var originStationData =  allStations.firstWhere((element) =>
                element.id == origin,
                    orElse: () {
                      return null;
                    });
                var originStationCordinate = originStationData.geo_point;
                nextTime = _coordinateDistance(originStationCordinate.latitude, originStationCordinate.longitude, nextStationCordinate.latitude, nextStationCordinate.longitude).round() * 3;
                if(nextTime < DateTime.now().difference(DateTime.parse(mTrains[i].stations[nextStation].toDate().toString())).inMinutes){
                  finalTrain = mTrains[i];
                  startStation = nextStationData;
                  break;
                }
              }
            }
          }
        }
      }

      // for(int i=0; i < mTrains.length; i++ ) {
      //   if (mTrains[i].stations.containsKey(origin)) {
      //     finalTrain = mTrains[i];
      //     break;
      //   }
      // }
      //   {
      //     var next = stations.indexOf(origin);
      //     var nextStation = stations[next+1];
      //     if(mTrains[i].stations.containsKey(nextStation)){
      //       for(int j = i; j< mTrains.length; j++) {
      //         if(mTrains[j].stations.containsKey(origin)){
      //           //compare
      //           var timeOriginTrain = mTrains[j].stations[destination].difference(mTrains[j].stations[origin]).inMinutes;
      //           var timeOtherTrain = mTrains[i].stations[destination].difference(mTrains[j].stations[nextStation]).inHours + _coordinateDistance(6.584116641918236, 79.95899519305465,6.235206820634703,80.05500014752478)/40;
      //           if(timeOriginTrain > timeOtherTrain){
      //             print(mTrains[j].train);
      //           }else{
      //             print(mTrains[i].train);
      //           }
      //         }else{
      //           //take this
      //           finalTrain = mTrains[i];
      //           break;
      //         }
      //       }
      //     }else if(mTrains[i].stations.containsKey(stations[--next])){
      //       for(int j = i; j< mTrains.length; j++) {
      //         if(mTrains[j].stations.containsKey(origin)){
      //           //compare
      //           // var xTrain = _coordinateDistance(station1 lat lon, station2 lat lon)/40
      //           // va yTrain = (previousTimestamp-currentTimestamp)/60
      //           //if(xTrain > yTrain) finalTrain = xTrain
      //           // finalTrain = yTrain
      //         }else{
      //           //take this
      //           finalTrain = mTrains[i];
      //           break;
      //         }
      //       }
      //     }
      //   }
      // }
      var destinationStation = allStations.firstWhere((element) =>
      element.id == destination,
          orElse: () {
            return null;
          });

      if(finalTrain != null){
        print(finalTrain.train);
        await _createPolylines(startStation.geo_point.latitude, startStation.geo_point.longitude, destinationStation.geo_point.latitude, destinationStation.geo_point.longitude, TravelMode.transit);
      }else{
        if(originTrain != null){
          print(originTrain.train);
          await _createPolylines(startStation.geo_point.latitude, startStation.geo_point.longitude, destinationStation.geo_point.latitude, destinationStation.geo_point.longitude, TravelMode.transit);
        }else{
          print("no train found");
        }
      }
      //else check whether the train stops in the +-station
      //if not get the other or tell no trains
      //else calculate time and compare

    }

  }


  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;


    return Container(
      height: height,
      width: width,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => {
            _getFastestTrain()
          },
        ),
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
                            'Places',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          SizedBox(height: 10),
                          _textField(
                              label: 'Start',
                              hint: 'Choose starting point',
                              prefixIcon: Icon(Icons.looks_one),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.my_location),
                                onPressed: () {
                                  startAddressController.text = _currentAddress;
                                  _startAddress = _currentAddress;
                                },
                              ),
                              controller: startAddressController,
                              focusNode: startAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _startAddress = value;
                                });
                              }),
                          SizedBox(height: 10),
                          _textField(
                              label: 'Destination',
                              hint: 'Choose destination',
                              prefixIcon: Icon(Icons.looks_two),
                              controller: destinationAddressController,
                              focusNode: desrinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _destinationAddress = value;
                                });
                              }),
                          SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'DISTANCE: $_placeDistance km',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty)
                                        polylines.clear();
                                      if (polylineCoordinates.isNotEmpty)
                                        polylineCoordinates.clear();
                                      _placeDistance = null;
                                    });

                                    _calculateDistance().then((isCalculated) {
                                      if (isCalculated) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Distance Calculated Sucessfully'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error Calculating Distance'),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Show Route'.toUpperCase(),
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
