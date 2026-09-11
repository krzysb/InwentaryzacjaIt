import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/domain/asset_status.dart';
import '../../assets/presentation/providers/asset_providers.dart';
import '../../dictionaries/presentation/dictionary_providers.dart';

/// Szybki przeglad stanu inwentarza: ile sprzetu, ile brakuje danych, jak
/// rozklada sie na kategorie/pomieszczenia/statusy. Pomaga zorientowac sie,
/// gdzie jeszcze jest balagan do posprzatania, bez przegladania calej listy.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _statusColor(AssetStatus status) => switch (status) {
    AssetStatus.sprawny => Colors.green,
    AssetStatus.uszkodzony => Colors.red,
    AssetStatus.wNaprawie => Colors.orange,
    AssetStatus.wycofany => Colors.grey,
    AssetStatus.zaginiony => Colors.purple,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(allAssetsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final locations = ref.watch(locationsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Statystyki')),
      body: assetsAsync.when(
        data: (allAssets) {
          if (allAssets.isEmpty) {
            return const Center(
              child: Text('Brak danych - dodaj pierwszy sprzet.'),
            );
          }
          final active = allAssets
              .where((a) => a.status != AssetStatus.wycofany)
              .toList();
          final incomplete = active.where((a) => a.isIncomplete).length;
          final retired = allAssets.length - active.length;

          final byStatus = <AssetStatus, int>{};
          for (final a in active) {
            byStatus[a.status] = (byStatus[a.status] ?? 0) + 1;
          }

          final byCategory = <String, int>{};
          for (final a in active) {
            byCategory[a.categoryId] = (byCategory[a.categoryId] ?? 0) + 1;
          }
          final categoryEntries = byCategory.entries.toList()
            ..sort((x, y) => y.value.compareTo(x.value));

          final byLocation = <String, int>{};
          for (final a in active) {
            if (a.locationId.isEmpty) continue;
            byLocation[a.locationId] = (byLocation[a.locationId] ?? 0) + 1;
          }
          final locationEntries = byLocation.entries.toList()
            ..sort((x, y) => y.value.compareTo(x.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Aktywny sprzet',
                      value: '${active.length}',
                      icon: Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Niekompletne',
                      value: '$incomplete',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Wycofane',
                      value: '$retired',
                      icon: Icons.archive_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Wg statusu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final status in AssetStatus.values)
                if ((byStatus[status] ?? 0) > 0)
                  _StatBar(
                    label: status.label,
                    count: byStatus[status] ?? 0,
                    total: active.length,
                    color: _statusColor(status),
                  ),
              const SizedBox(height: 24),
              Text(
                'Wg kategorii',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final entry in categoryEntries)
                _StatBar(
                  label:
                      categories
                          .where((c) => c.id == entry.key)
                          .map((c) => c.name)
                          .firstOrNull ??
                      entry.key,
                  count: entry.value,
                  total: active.length,
                  color: Theme.of(context).colorScheme.primary,
                ),
              const SizedBox(height: 24),
              Text(
                'Wg pomieszczenia (top 8)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final entry in locationEntries.take(8))
                _StatBar(
                  label:
                      locations
                          .where((l) => l.id == entry.key)
                          .map((l) => l.displayName)
                          .firstOrNull ??
                      entry.key,
                  count: entry.value,
                  total: active.length,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              if (locationEntries.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${locationEntries.length - 8} innych pomieszczen',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Blad wczytywania: $error')),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
