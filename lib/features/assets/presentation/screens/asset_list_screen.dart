import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../dictionaries/presentation/dictionary_providers.dart';
import '../providers/asset_providers.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_filter_bar.dart';

class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprzet IT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import z pliku',
            onPressed: () => context.push('/import'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Znajdz sprzet (skan)',
            onPressed: () => context.push('/scan-find'),
          ),
        ],
      ),
      body: Column(
        children: [
          const AssetFilterBar(),
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Center(
                    child: Text('Brak sprzetu spelniajacego kryteria.'),
                  );
                }
                final categories = categoriesAsync.value ?? [];
                final locations = locationsAsync.value ?? [];
                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return AssetCard(
                      asset: asset,
                      category: categories.byId(asset.categoryId),
                      location: locations.byId(asset.locationId),
                      onTap: () => context.push('/assets/${asset.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Blad wczytywania: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assets/new'),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj sprzet'),
      ),
    );
  }
}
