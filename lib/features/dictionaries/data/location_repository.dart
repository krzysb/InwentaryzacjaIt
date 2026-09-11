import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/location.dart';

class LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('locations');

  Stream<List<Location>> watchLocations() {
    return _locations
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Location.fromFirestore).toList());
  }

  Future<String> upsertLocation(Location location) async {
    if (location.id.isEmpty) {
      final doc = await _locations.add(location.toFirestore());
      return doc.id;
    }
    await _locations.doc(location.id).set(location.toFirestore());
    return location.id;
  }

  Future<void> deleteLocation(String id) async {
    await _locations.doc(id).delete();
  }
}
