import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../dictionaries/presentation/dictionary_providers.dart';
import '../../../scanner/presentation/scanner_screen.dart';
import '../../domain/asset.dart';
import '../../domain/asset_status.dart';
import '../providers/asset_providers.dart';

/// Formularz dodawania/edycji sprzetu. Gdy [assetId] jest null, tworzymy nowy
/// rekord (z nowym assetTag do wydrukowania na etykiecie); w przeciwnym razie
/// edytujemy istniejacy.
class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;

  const AssetFormScreen({super.key, this.assetId});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialController = TextEditingController();
  final _vulcanController = TextEditingController();
  final _notesController = TextEditingController();

  String? _categoryId;
  String? _locationId;
  AssetStatus _status = AssetStatus.sprawny;
  bool _saving = false;
  bool _loadedExisting = false;
  Asset? _existingAsset;

  bool get _isEditing => widget.assetId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _serialController.dispose();
    _vulcanController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadFromAsset(Asset asset) {
    if (_loadedExisting) return;
    _loadedExisting = true;
    _existingAsset = asset;
    _nameController.text = asset.name;
    _manufacturerController.text = asset.manufacturer ?? '';
    _serialController.text = asset.serialNumber ?? '';
    _vulcanController.text = asset.vulcanNumber ?? '';
    _notesController.text = asset.notes;
    _categoryId = asset.categoryId;
    _locationId = asset.locationId;
    _status = asset.status;
  }

  Future<void> _scanSerialNumber() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(
          mode: ScannerMode.fillField,
          title: 'Skanuj numer seryjny',
        ),
      ),
    );
    if (value != null) {
      setState(() => _serialController.text = value);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz kategorie i pomieszczenie.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(assetRepositoryProvider);
      final now = DateTime.now();
      if (_isEditing && _existingAsset != null) {
        final updated = _existingAsset!.copyWith(
          name: _nameController.text.trim(),
          manufacturer: _manufacturerController.text.trim(),
          serialNumber: _serialController.text.trim(),
          vulcanNumber: _vulcanController.text.trim(),
          categoryId: _categoryId,
          locationId: _locationId,
          status: _status,
          notes: _notesController.text.trim(),
          updatedAt: now,
          updatedBy: 'current-user',
        );
        await repo.updateAsset(updated);
      } else {
        final asset = Asset(
          id: '',
          assetTag: const Uuid().v4().substring(0, 8).toUpperCase(),
          categoryId: _categoryId!,
          name: _nameController.text.trim(),
          manufacturer: _manufacturerController.text.trim(),
          serialNumber: _serialController.text.trim(),
          vulcanNumber: _vulcanController.text.trim(),
          locationId: _locationId!,
          status: _status,
          notes: _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
          createdBy: 'current-user',
          updatedBy: 'current-user',
        );
        final existing = asset.serialNumber!.isEmpty
            ? null
            : await repo.findBySerialNumber(asset.serialNumber!);
        if (existing != null && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Mozliwy duplikat'),
              content: Text(
                'Sprzet o numerze seryjnym "${asset.serialNumber}" juz istnieje '
                '(${existing.name}). Dodac mimo to?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Dodaj mimo to'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            setState(() => _saving = false);
            return;
          }
        }
        await repo.createAsset(asset);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final assetAsync = _isEditing
        ? ref.watch(assetDetailProvider(widget.assetId!))
        : null;

    if (assetAsync != null) {
      assetAsync.whenData((asset) {
        if (asset != null) _loadFromAsset(asset);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edytuj sprzet' : 'Dodaj sprzet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nazwa / model *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Podaj nazwe' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(labelText: 'Producent'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serialController,
                decoration: InputDecoration(
                  labelText: 'Numer seryjny',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanSerialNumber,
                    tooltip: 'Skanuj numer seryjny',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vulcanController,
                decoration: const InputDecoration(
                  labelText: 'Numer z ewidencji Vulcan',
                ),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategoria *'),
                  items: categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Blad: $e'),
              ),
              const SizedBox(height: 12),
              locationsAsync.when(
                data: (locations) => DropdownButtonFormField<String>(
                  initialValue: _locationId,
                  decoration: const InputDecoration(
                    labelText: 'Pomieszczenie *',
                  ),
                  items: locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _locationId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Blad: $e'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AssetStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: AssetStatus.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notatki'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Zapisz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
