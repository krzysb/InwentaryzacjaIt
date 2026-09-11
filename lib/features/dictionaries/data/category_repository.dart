import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories => _firestore.collection('categories');

  Stream<List<Category>> watchCategories() {
    return _categories.orderBy('sortOrder').snapshots().map(
          (snapshot) => snapshot.docs.map(Category.fromFirestore).toList(),
        );
  }

  Future<void> upsertCategory(Category category) async {
    await _categories.doc(category.id).set(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  /// Wypelnia kolekcje domyslnymi kategoriami sprzetu IT, jesli jest pusta -
  /// wywolywane raz przy pierwszym uruchomieniu aplikacji przez admina.
  Future<void> seedDefaultsIfEmpty() async {
    final snapshot = await _categories.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final category in Category.defaultSeed) {
      batch.set(_categories.doc(category.id), category.toFirestore());
    }
    await batch.commit();
  }
}
