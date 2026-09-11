import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../dictionaries/presentation/dictionary_providers.dart';
import '../../domain/asset_status.dart';
import '../../domain/history_entry.dart';
import '../providers/asset_providers.dart';
import '../widgets/asset_filter_bar.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetDetailProvider(assetId));
    final historyAsync = ref.watch(assetHistoryProvider(assetId));
    final categories = ref.watch(categoriesProvider).value ?? [];
    final locations = ref.watch(locationsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegoly sprzetu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/assets/$assetId/edit'),
          ),
        ],
      ),
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return const Center(child: Text('Nie znaleziono sprzetu.'));
          }
          final category = categories.byId(asset.categoryId);
          final location = locations.byId(asset.locationId);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(asset.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('ID: ${asset.assetTag}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _InfoRow(label: 'Kategoria', value: category?.name ?? asset.categoryId),
              _InfoRow(label: 'Pomieszczenie', value: location?.displayName ?? asset.locationId),
              _InfoRow(label: 'Status', value: asset.status.label),
              _InfoRow(label: 'Producent', value: asset.manufacturer ?? '-'),
              _InfoRow(label: 'Numer seryjny', value: asset.serialNumber ?? '-'),
              _InfoRow(label: 'Numer z ewidencji Vulcan', value: asset.vulcanNumber ?? '-'),
              if (asset.notes.isNotEmpty) _InfoRow(label: 'Notatki', value: asset.notes),
              if (asset.isIncomplete)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rekord niekompletny - brakuje numeru seryjnego, numeru Vulcan lub lokalizacji.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.move_down),
                      label: const Text('Przenies'),
                      onPressed: () => _showMoveDialog(context, ref, assetId, locations),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sync_alt),
                      label: const Text('Zmien status'),
                      onPressed: () => _showStatusDialog(context, ref, assetId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Historia', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return const Text('Brak zapisanych zmian.');
                  }
                  return Column(
                    children: history.map((h) => _HistoryTile(entry: h)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Blad wczytywania historii: $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Blad wczytywania: $error')),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref, String assetId, List locations) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selected;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Przenies sprzet'),
              content: DropdownButtonFormField<String>(
                initialValue: selected,
                items: locations
                    .map<DropdownMenuItem<String>>(
                      (l) => DropdownMenuItem(value: l.id as String, child: Text(l.displayName as String)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
                decoration: const InputDecoration(labelText: 'Nowe pomieszczenie'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Anuluj')),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          final repo = ref.read(assetRepositoryProvider);
                          final asset = ref.read(assetDetailProvider(assetId)).value;
                          if (asset == null) return;
                          final fromId = asset.locationId;
                          await repo.updateAssetWithHistory(
                            updatedAsset: asset.copyWith(locationId: selected!, updatedAt: DateTime.now()),
                            type: HistoryEntryType.locationChange,
                            fromValue: fromId,
                            toValue: selected,
                            changedBy: 'current-user',
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

  void _showStatusDialog(BuildContext context, WidgetRef ref, String assetId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        AssetStatus? selected;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Zmien status'),
              content: DropdownButtonFormField<AssetStatus>(
                initialValue: selected,
                items: AssetStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
                decoration: const InputDecoration(labelText: 'Nowy status'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Anuluj')),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          final repo = ref.read(assetRepositoryProvider);
                          final asset = ref.read(assetDetailProvider(assetId)).value;
                          if (asset == null) return;
                          final fromStatus = asset.status;
                          await repo.updateAssetWithHistory(
                            updatedAsset: asset.copyWith(status: selected!, updatedAt: DateTime.now()),
                            type: HistoryEntryType.statusChange,
                            fromValue: fromStatus.name,
                            toValue: selected!.name,
                            changedBy: 'current-user',
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryTile({required this.entry});

  String get _typeLabel => switch (entry.type) {
        HistoryEntryType.locationChange => 'Zmiana lokalizacji',
        HistoryEntryType.statusChange => 'Zmiana statusu',
        HistoryEntryType.edit => 'Edycja',
      };

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history),
      title: Text('$_typeLabel: ${entry.fromValue ?? '-'} -> ${entry.toValue ?? '-'}'),
      subtitle: Text('${formatter.format(entry.changedAt)} • ${entry.changedBy}'),
    );
  }
}
