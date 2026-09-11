import 'package:cloud_firestore/cloud_firestore.dart';

enum LocationType { salaLekcyjna, serwerownia, magazyn, sekretariat, inne }

class Location {
  final String id;
  final String name;
  final String? building;
  final String? floor;
  final LocationType type;

  const Location({
    required this.id,
    required this.name,
    this.building,
    this.floor,
    this.type = LocationType.salaLekcyjna,
  });

  String get displayName => building == null ? name : '$name ($building)';

  factory Location.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Location(
      id: doc.id,
      name: data['name'] as String? ?? '',
      building: data['building'] as String?,
      floor: data['floor'] as String?,
      type: LocationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => LocationType.salaLekcyjna,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'building': building,
        'floor': floor,
        'type': type.name,
      };
}
