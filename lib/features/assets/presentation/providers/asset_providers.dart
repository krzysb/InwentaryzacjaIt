import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_repository.dart';
import '../../domain/asset.dart';
import '../../domain/history_entry.dart';

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => AssetRepository(),
);

class AssetFilterNotifier extends Notifier<AssetFilter> {
  @override
  AssetFilter build() => const AssetFilter();

  void setSearchText(String text) => state = state.copyWith(searchText: text);

  void setCategory(String? categoryId) => state = state.copyWith(
    categoryId: categoryId,
    clearCategory: categoryId == null,
  );

  void setLocation(String? locationId) => state = state.copyWith(
    locationId: locationId,
    clearLocation: locationId == null,
  );

  void setOnlyIncomplete(bool value) =>
      state = state.copyWith(onlyIncomplete: value);

  void reset() => state = const AssetFilter();
}

final assetFilterProvider = NotifierProvider<AssetFilterNotifier, AssetFilter>(
  AssetFilterNotifier.new,
);

final assetListProvider = StreamProvider<List<Asset>>((ref) {
  final filter = ref.watch(assetFilterProvider);
  return ref.watch(assetRepositoryProvider).watchAssets(filter);
});

/// Caly (niefiltrowany) sprzet - niezalezny od filtrow ustawionych na
/// glownej liscie. Uzywane tam, gdzie trzeba widziec wszystko naraz
/// (wykrywanie duplikatow, statystyki).
final allAssetsProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(assetRepositoryProvider).watchAssets(const AssetFilter());
});

final assetDetailProvider = StreamProvider.family<Asset?, String>((ref, id) {
  return ref.watch(assetRepositoryProvider).watchAsset(id);
});

final assetHistoryProvider = StreamProvider.family<List<HistoryEntry>, String>((
  ref,
  assetId,
) {
  return ref.watch(assetRepositoryProvider).watchHistory(assetId);
});
