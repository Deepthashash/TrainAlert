import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedTrainModel{
  final String id;
  final String train;
  final Map<dynamic,dynamic> stations;

  SelectedTrainModel({this.id, this.train, this.stations});
}