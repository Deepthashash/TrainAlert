import 'package:cloud_firestore/cloud_firestore.dart';

class TrainService{
  final CollectionReference trainCollection = FirebaseFirestore.instance.collection('Trains');

  Stream<QuerySnapshot> get trains {
    return trainCollection.snapshots();
  }
}