import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/domain/asset.dart';
import '../../assets/presentation/providers/asset_providers.dart';
import '../../assets/presentation/widgets/asset_filter_bar.dart';
import '../../dictionaries/presentation/dictionary_providers.dart';

/// Ekran scalania dwoch rekordow uznanych za duplikaty: dla kazdego pola
/// mozna wybrac, ktora wersja zachowac. Rekord [assetA] pozostaje w bazie
/// (z wybranymi wartosciami pol), [assetB] zostaje oznaczony jako wycofany
/// duplikat [assetA] - nie jest usuwany, zeby nie stracic historii/sladu.
class MergeScreen extends ConsumerStatefulWidget {
  final Asset assetA;
  final Asset assetB;

  const MergeScreen({super.key, required this.assetA, required this.assetB});

  @override
  ConsumerState<MergeScreen> createState() => _MergeScreenState();
}

enum _Pick { a, b }

class _MergeScreenState extends ConsumerState<MergeScreen> {
  late final Map<String, _Pick> _choice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.assetA;
    final b = widget.assetB;
    _choice = {
      'name': _preferNonEmpty(a.name, b.name),
      'manufacturer': _preferNonEmpty(
        a.manufacturer ?? '',
        b.manufacturer ?? '',
      ),
      'categoryId': _preferNonEmpty(a.categoryId, b.categoryId),
      'locationId': _preferNonEmpty(a.locationId, b.locationId),
      'vulcanNumber': _preferNonEmpty(
        a.vulcanNumber ?? '',
        b.vulcanNumber ?? '',
      ),
      'notes': _preferNonEmpty(a.notes, b.notes),
    };
  }

  _Pick _preferNonEmpty(String aValue, String bValue) {
    if (aValue.trim().isEmpty && bValue.trim().isNotEmpty) return _Pick.b;
    return _Pick.a;
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final a = widget.assetA;
      final b = widget.assetB;
      final merged = a.copyWith(
        name: _choice['name'] == _Pick.a ? a.name : b.name,
        manufacturer: _choice['manufacturer'] == _Pick.a
            ? a.manufacturer
            : b.manufacturer,
        categoryId: _choice['categoryId'] == _Pick.a
            ? a.categoryId
            : b.categoryId,
        locationId: _choice['locationId'] == _Pick.a
            ? a.locationId
            : b.locationId,
        vulcanNumber: _choice['vulcanNumber'] == _Pick.a
            ? a.vulcanNumber
            : b.vulcanNumber,
        notes: _choice['notes'] == _Pick.a ? a.notes : b.notes,
        updatedAt: DateTime.now(),
        updatedBy: 'current-user',
      );
      await ref
          .read(assetRepositoryProvider)
          .mergeAssets(
            duplicate: b,
            mergedPrimary: merged,
            changedBy: 'current-user',
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final locations = ref.watch(locationsProvider).value ?? [];
    final a = widget.assetA;
    final b = widget.assetB;

    return Scaffold(
      appBar: AppBar(title: const Text('Scal duplikaty')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Wybierz, ktora wersja kazdego pola zachowac. Drugi rekord '
            'zostanie oznaczony jako wycofany duplikat pierwszego (nie '
            'usuwamy go, zeby nie stracic historii).',
          ),
          const SizedBox(height: 16),
          _FieldChoice(
            label: 'Nazwa',
            fieldKey: 'name',
            valueA: a.name,
            valueB: b.name,
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          _FieldChoice(
            label: 'Producent',
            fieldKey: 'manufacturer',
            valueA: a.manufacturer ?? '-',
            valueB: b.manufacturer ?? '-',
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          _FieldChoice(
            label: 'Kategoria',
            fieldKey: 'categoryId',
            valueA: categories.byId(a.categoryId)?.name ?? a.categoryId,
            valueB: categories.byId(b.categoryId)?.name ?? b.categoryId,
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          _FieldChoice(
            label: 'Pomieszczenie',
            fieldKey: 'locationId',
            valueA: locations.byId(a.locationId)?.displayName ?? a.locationId,
            valueB: locations.byId(b.locationId)?.displayName ?? b.locationId,
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          _FieldChoice(
            label: 'Numer Vulcan',
            fieldKey: 'vulcanNumber',
            valueA: a.vulcanNumber ?? '-',
            valueB: b.vulcanNumber ?? '-',
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          _FieldChoice(
            label: 'Notatki',
            fieldKey: 'notes',
            valueA: a.notes.isEmpty ? '-' : a.notes,
            valueB: b.notes.isEmpty ? '-' : b.notes,
            choice: _choice,
            onChanged: (k, p) => setState(() => _choice[k] = p),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _confirm,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Scal rekordy'),
          ),
        ],
      ),
    );
  }
}

class _FieldChoice extends StatelessWidget {
  final String label;
  final String fieldKey;
  final String valueA;
  final String valueB;
  final Map<String, _Pick> choice;
  final void Function(String fieldKey, _Pick pick) onChanged;

  const _FieldChoice({
    required this.label,
    required this.fieldKey,
    required this.valueA,
    required this.valueB,
    required this.choice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final picked = choice[fieldKey] ?? _Pick.a;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              RadioListTile<_Pick>(
                dense: true,
                value: _Pick.a,
                groupValue: picked,
                onChanged: (p) => onChanged(fieldKey, p!),
                title: Text(valueA, overflow: TextOverflow.ellipsis),
              ),
              RadioListTile<_Pick>(
                dense: true,
                value: _Pick.b,
                groupValue: picked,
                onChanged: (p) => onChanged(fieldKey, p!),
                title: Text(valueB, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
