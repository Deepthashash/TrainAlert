import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:train_alert/models/app_constant.dart';
import 'package:train_alert/models/stationModel.dart';

class TrainsAndStations extends StatefulWidget {
  const TrainsAndStations({key}) : super(key: key);

  @override
  _TrainsAndStationsState createState() => _TrainsAndStationsState();
}

class _TrainsAndStationsState extends State<TrainsAndStations> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraPosition _initialLocation = CameraPosition(
      bearing: 30,
      target: LatLng(6.584116641918236, 79.95899519305465),
      tilt: 45,
      zoom: 11);

  // 90.3842538), zoom: 13);
  GoogleMapController mapController;
  BitmapDescriptor customIcon;
  final Set<Marker> listMarkers = {};

  Iterable markers = [];
  List<StationModel> allStations = [];

  Iterable _markers;


  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    createMarker(context);
    // markers = Iterable.generate(AppConstant.list.length, (index) {
    //   return Marker(
    //       markerId: MarkerId(AppConstant.list[index]['id']),
    //       position: LatLng(
    //         AppConstant.list[index]['lat'],
    //         AppConstant.list[index]['lon'],
    //       ),
    //       infoWindow: InfoWindow(title: AppConstant.list[index]["title"]),
    //       icon: customIcon
    //   );
    // });
    return Container(
        height: height,
        width: width,
        child: Scaffold(
            key: _scaffoldKey,
            body: Stack(children: <Widget>[
              // Map View
              GoogleMap(
                markers: listMarkers,
                initialCameraPosition: _initialLocation,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                // polylines: Set<Polyline>.of(polylines.values),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
              )
            ])));
  }

  @override
  void initState() {
    super.initState();
    _getStationLocations();
    _getTrainLocations();
  }

  void setCustomMarker() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/images/logo.jpg');
  }

  void _getTrainLocations() {
    int id = 30;
    FirebaseFirestore.instance
        .collection('Trains')
        .orderBy('id')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        GeoPoint geoPoint = doc["geo_point"];
        listMarkers.add(Marker(
          markerId: MarkerId(id.toString()),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          infoWindow: InfoWindow(title: doc["train"]),
            icon: customIcon));
        // print(model);
        // stationData.add(model);
        id++;
      });
      setState(() {
        // this.allStations = stationData;
      });
    });
  }
  void _getStationLocations() {
    List<StationModel> stationData = [];
    int id = 0;
    FirebaseFirestore.instance
        .collection('Train Stations')
        .orderBy('id')
        .limit(19)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var model = StationModel(id:doc.id,xid:doc["id"],name:doc["name"],timestamp:doc["timestamp"],geo_point:doc["geo_point"]);
        GeoPoint geoPoint = doc["geo_point"];
        listMarkers.add(Marker(
            markerId: MarkerId(id.toString()),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(title: doc["name"]),
        ));
        // print(model);
        // stationData.add(model);
        id++;
      });
      setState(() {
        // this.allStations = stationData;
      });
    });
  }

  createMarker(context) {
    if (customIcon == null) {
      ImageConfiguration configuration = ImageConfiguration(devicePixelRatio: 0.1);
      BitmapDescriptor.fromAssetImage(configuration, 'assets/images/train.png')
          .then((icon) {
        setState(() {
          customIcon = icon;
        });
      });
    }
  }
}
