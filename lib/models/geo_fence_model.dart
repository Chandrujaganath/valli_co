import 'package:cloud_firestore/cloud_firestore.dart';

class GeoFenceModel {
  final String id;
  final GeoPoint location;
  final double radius;
  final String name;

  GeoFenceModel({
    required this.id,
    required this.location,
    required this.radius,
    required this.name,
  });

  factory GeoFenceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeoFenceModel(
      id: doc.id,
      location: data['location'],
      radius: data['radius'],
      name: data['name'],
    );
  }
}
