import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../data/location_repository.dart';
import '../domain/category.dart';
import '../domain/location.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository());
final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository());

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final locationsProvider = StreamProvider<List<Location>>((ref) {
  return ref.watch(locationRepositoryProvider).watchLocations();
});
