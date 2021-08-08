import 'package:cloud_firestore/cloud_firestore.dart';

class TrainDistanceModel {
  final String id;
  final int xid;
  final String name;
  final Timestamp timestamp;
  final GeoPoint geo_point;
  final double distance;
  final int timeDuration;

  TrainDistanceModel(
      {this.id, this.xid, this.name, this.timestamp, this.geo_point, this.distance, this.timeDuration});
}