import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../assets/domain/asset.dart';
import '../../assets/presentation/providers/asset_providers.dart';
import '../../assets/presentation/widgets/asset_filter_bar.dart';
import '../../dictionaries/presentation/dictionary_providers.dart';
import '../data/label_pdf_generator.dart';

/// Ekran wyboru sprzetu do wydrukowania etykiet QR. Domyslnie zaznaczony
/// jest caly widoczny sprzet (uwzglednia biezace filtry z listy sprzetu) -
/// odznaczenie pojedynczych pozycji jest szybsze niz zaznaczanie od zera,
/// gdy trzeba dodrukowac tylko kilka etykiet.
class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  final Set<String> _selectedIds = {};
  bool _initialized = false;
  bool _generating = false;

  void _initSelection(List<Asset> assets) {
    if (_initialized) return;
    _initialized = true;
    _selectedIds.addAll(assets.map((a) => a.id));
  }

  Future<void> _generate(List<Asset> allAssets) async {
    final selected = allAssets
        .where((a) => _selectedIds.contains(a.id))
        .toList();
    if (selected.isEmpty) return;
    setState(() => _generating = true);
    try {
      final bytes = await LabelPdfGenerator.build(selected);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetListProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final locations = ref.watch(locationsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Etykiety QR')),
      body: assetsAsync.when(
        data: (assets) {
          _initSelection(assets);
          if (assets.isEmpty) {
            return const Center(child: Text('Brak sprzetu do wydrukowania.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'Zaznaczono: ${_selectedIds.length} / ${assets.length}',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(
                        () => _selectedIds.addAll(assets.map((a) => a.id)),
                      ),
                      child: const Text('Zaznacz wszystkie'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selectedIds.clear),
                      child: const Text('Odznacz'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    final category = categories.byId(asset.categoryId);
                    final location = locations.byId(asset.locationId);
                    return CheckboxListTile(
                      value: _selectedIds.contains(asset.id),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _selectedIds.add(asset.id);
                        } else {
                          _selectedIds.remove(asset.id);
                        }
                      }),
                      title: Text(asset.name),
                      subtitle: Text(
                        '${category?.name ?? asset.categoryId} • '
                        '${location?.displayName ?? asset.locationId} • '
                        'ID: ${asset.assetTag}',
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _generating || _selectedIds.isEmpty
                      ? null
                      : () => _generate(assets),
                  icon: _generating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text('Drukuj etykiety (${_selectedIds.length})'),
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
