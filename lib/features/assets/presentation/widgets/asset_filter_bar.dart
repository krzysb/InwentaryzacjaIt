import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dictionaries/domain/category.dart';
import '../../../dictionaries/domain/location.dart';
import '../../../dictionaries/presentation/dictionary_providers.dart';
import '../providers/asset_providers.dart';

class AssetFilterBar extends ConsumerWidget {
  const AssetFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(assetFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Szukaj (nazwa, numer seryjny, numer Vulcan, ID)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(assetFilterProvider.notifier).setSearchText(value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                categoriesAsync.when(
                  data: (categories) => _DropdownChip<String>(
                    label: 'Kategoria',
                    value: filter.categoryId,
                    items: {for (final c in categories) c.id: c.name},
                    onChanged: (v) => ref.read(assetFilterProvider.notifier).setCategory(v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                locationsAsync.when(
                  data: (locations) => _DropdownChip<String>(
                    label: 'Pomieszczenie',
                    value: filter.locationId,
                    items: {for (final l in locations) l.id: l.displayName},
                    onChanged: (v) => ref.read(assetFilterProvider.notifier).setLocation(v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Niekompletne'),
                  selected: filter.onlyIncomplete,
                  onSelected: (v) => ref.read(assetFilterProvider.notifier).setOnlyIncomplete(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T?>(
      label: Text(label),
      initialSelection: value,
      textStyle: const TextStyle(fontSize: 13),
      onSelected: onChanged,
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: null, label: 'Wszystkie'),
        ...items.entries.map((e) => DropdownMenuEntry(value: e.key, label: e.value)),
      ],
    );
  }
}

extension AssetCategoryLookup on List<Category> {
  Category? byId(String id) => where((c) => c.id == id).firstOrNull;
}

extension AssetLocationLookup on List<Location> {
  Location? byId(String id) => where((l) => l.id == id).firstOrNull;
}
