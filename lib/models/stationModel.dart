import 'package:cloud_firestore/cloud_firestore.dart';

class StationModel{
  final String id;
  final int xid;
  final String name;
  final Timestamp timestamp;
  final GeoPoint geo_point;

  StationModel({this.id,this.xid, this.name, this.timestamp, this.geo_point});
}