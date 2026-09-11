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
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statystyki',
            onPressed: () => context.push('/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Znajdz sprzet (skan)',
            onPressed: () => context.push('/scan-find'),
          ),
          PopupMenuButton<String>(
            onSelected: (route) => context.push(route),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: '/import',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Import z pliku'),
                ),
              ),
              PopupMenuItem(
                value: '/labels',
                child: ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text('Drukuj etykiety'),
                ),
              ),
              PopupMenuItem(
                value: '/dictionaries',
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Slowniki'),
                ),
              ),
              PopupMenuItem(
                value: '/duplicates',
                child: ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text('Mozliwe duplikaty'),
                ),
              ),
            ],
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
