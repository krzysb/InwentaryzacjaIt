import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.icon = 'devices_other',
    this.sortOrder = 0,
  });

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? '',
      icon: data['icon'] as String? ?? 'devices_other',
      sortOrder: data['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'icon': icon,
        'sortOrder': sortOrder,
      };

  /// Domyslny zestaw kategorii typowego sprzetu IT w szkole - startowy seed,
  /// gdy kolekcja `categories` jest jeszcze pusta.
  static const List<Category> defaultSeed = [
    Category(id: 'komputer-stacjonarny', name: 'Komputer stacjonarny', icon: 'computer', sortOrder: 0),
    Category(id: 'laptop', name: 'Laptop', icon: 'laptop', sortOrder: 1),
    Category(id: 'monitor', name: 'Monitor', icon: 'monitor', sortOrder: 2),
    Category(id: 'projektor', name: 'Projektor', icon: 'videocam', sortOrder: 3),
    Category(id: 'drukarka', name: 'Drukarka', icon: 'print', sortOrder: 4),
    Category(id: 'switch', name: 'Switch / router', icon: 'router', sortOrder: 5),
    Category(id: 'ups', name: 'UPS', icon: 'battery_charging_full', sortOrder: 6),
    Category(id: 'tablet', name: 'Tablet', icon: 'tablet', sortOrder: 7),
    Category(id: 'tablica-interaktywna', name: 'Tablica interaktywna', icon: 'dashboard', sortOrder: 8),
    Category(id: 'inne', name: 'Inne', icon: 'category', sortOrder: 99),
  ];
}
