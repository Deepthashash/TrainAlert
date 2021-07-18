import 'package:cloud_firestore/cloud_firestore.dart';

class StationModel{
  final String id;
  final String name;
  final Timestamp timestamp;
  final GeoPoint geo_point;

  StationModel({this.id, this.name, this.timestamp, this.geo_point});
}