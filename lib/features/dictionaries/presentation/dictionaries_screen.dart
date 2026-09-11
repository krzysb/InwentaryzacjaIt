import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';
import '../domain/location.dart';
import 'dictionary_providers.dart';

/// Zarzadzanie slownikami (kategorie/pomieszczenia) bezposrednio w appce -
/// bez tego trzeba by dodawac te dane recznie w konsoli Firebase.
class DictionariesScreen extends StatelessWidget {
  const DictionariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Slowniki'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kategorie'),
              Tab(text: 'Pomieszczenia'),
            ],
          ),
        ),
        body: const TabBarView(children: [_CategoriesTab(), _LocationsTab()]),
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Brak kategorii.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _confirmDeleteCategory(context, ref, category),
                ),
                onTap: () =>
                    _showCategoryDialog(context, ref, category: category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Blad wczytywania: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) {
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Nowa kategoria' : 'Edytuj kategorie'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nazwa'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(categoryRepositoryProvider)
                    .upsertCategory(
                      Category(
                        id: category?.id ?? '',
                        name: name,
                        sortOrder: category?.sortOrder ?? 50,
                      ),
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usunac kategorie?'),
        content: Text(
          'Sprzet przypisany do kategorii "${category.name}" nie zostanie usuniety, '
          'ale bedzie pokazywal ID zamiast nazwy kategorii.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await ref
                  .read(categoryRepositoryProvider)
                  .deleteCategory(category.id);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Usun'),
          ),
        ],
      ),
    );
  }
}

class _LocationsTab extends ConsumerWidget {
  const _LocationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    return Scaffold(
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return const Center(child: Text('Brak pomieszczen.'));
          }
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                title: Text(location.name),
                subtitle: Text(
                  _typeLabel(location.type) +
                      (location.building != null
                          ? ' • ${location.building}'
                          : ''),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _confirmDeleteLocation(context, ref, location),
                ),
                onTap: () =>
                    _showLocationDialog(context, ref, location: location),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Blad wczytywania: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _typeLabel(LocationType type) => switch (type) {
    LocationType.salaLekcyjna => 'Sala lekcyjna',
    LocationType.serwerownia => 'Serwerownia',
    LocationType.magazyn => 'Magazyn',
    LocationType.sekretariat => 'Sekretariat',
    LocationType.inne => 'Inne',
  };

  void _showLocationDialog(
    BuildContext context,
    WidgetRef ref, {
    Location? location,
  }) {
    final nameController = TextEditingController(text: location?.name ?? '');
    final buildingController = TextEditingController(
      text: location?.building ?? '',
    );
    var selectedType = location?.type ?? LocationType.salaLekcyjna;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                location == null
                    ? 'Nowe pomieszczenie'
                    : 'Edytuj pomieszczenie',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa (np. Sala 12)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buildingController,
                    decoration: const InputDecoration(
                      labelText: 'Budynek (opcjonalnie)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LocationType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: LocationType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_typeLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (t) =>
                        setState(() => selectedType = t ?? selectedType),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final building = buildingController.text.trim();
                    await ref
                        .read(locationRepositoryProvider)
                        .upsertLocation(
                          Location(
                            id: location?.id ?? '',
                            name: name,
                            building: building.isEmpty ? null : building,
                            floor: location?.floor,
                            type: selectedType,
                          ),
                        );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteLocation(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usunac pomieszczenie?'),
        content: Text(
          'Sprzet przypisany do "${location.name}" nie zostanie usuniety, '
          'ale bedzie pokazywal ID zamiast nazwy pomieszczenia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await ref
                  .read(locationRepositoryProvider)
                  .deleteLocation(location.id);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Usun'),
          ),
        ],
      ),
    );
  }
}
