import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/domain/asset.dart';
import '../../dictionaries/domain/category.dart';
import '../../dictionaries/domain/location.dart';
import '../../dictionaries/presentation/dictionary_providers.dart';
import '../data/spreadsheet_parser.dart';
import '../domain/classify_rows.dart';
import '../domain/import_models.dart';
import 'import_providers.dart';

enum _WizardStep { pickFile, mapColumns, review, done }

/// Kreator importu CSV/Excel. Obsluguje pliki z preambula przed naglowkiem
/// i wieloma arkuszami (jak realny eksport KPO/Vulcan), pozwala zmapowac
/// dowolne nazwy kolumn na pola sprzetu, klasyfikuje wiersze wzgledem
/// istniejacej bazy (nowy/duplikat/konflikt/blad) i pozwala doprecyzowac
/// przypisanie kategorii/pomieszczen przed zapisem.
class ImportWizardScreen extends ConsumerStatefulWidget {
  const ImportWizardScreen({super.key});

  @override
  ConsumerState<ImportWizardScreen> createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends ConsumerState<ImportWizardScreen> {
  _WizardStep _step = _WizardStep.pickFile;
  bool _busy = false;
  String? _error;

  String? _fileName;
  Uint8List? _fileBytes;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  List<List<String>> _rawRows = [];
  int _headerRowIndex = 0;

  Map<int, ImportField> _columnMapping = {};
  List<ImportRowResult> _classified = [];
  final Map<String, String?> _categoryValueMap = {};
  final Map<String, String?> _locationValueMap = {};

  ImportSummary? _summary;

  bool get _isExcel => (_fileName ?? '').toLowerCase().endsWith('.xlsx');

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = 'Nie udalo sie odczytac pliku.');
        return;
      }
      _fileName = file.name;
      _fileBytes = bytes;
      if (_isExcel) {
        _sheetNames = SpreadsheetParser.listExcelSheets(bytes);
        _selectedSheet = _sheetNames.isNotEmpty ? _sheetNames.first : null;
        if (_selectedSheet != null) {
          _loadExcelSheet(_selectedSheet!);
        }
      } else {
        _rawRows = SpreadsheetParser.parseCsv(bytes);
        _headerRowIndex = SpreadsheetParser.guessHeaderRow(_rawRows);
      }
      if (_rawRows.isNotEmpty) {
        setState(() => _step = _WizardStep.mapColumns);
      } else {
        setState(
          () => _error = 'Plik jest pusty albo nie udalo sie go odczytac.',
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  void _loadExcelSheet(String sheetName) {
    _rawRows = SpreadsheetParser.parseExcelSheet(_fileBytes!, sheetName);
    _headerRowIndex = SpreadsheetParser.guessHeaderRow(_rawRows);
    _columnMapping = {};
  }

  List<String> get _headerCells =>
      _headerRowIndex < _rawRows.length ? _rawRows[_headerRowIndex] : const [];

  int get _columnCount {
    var max = 0;
    for (final row in _rawRows) {
      if (row.length > max) max = row.length;
    }
    return max;
  }

  Future<void> _runClassification() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(importRepositoryProvider);
      final existingSerials = await repo.existingSerialNumbers();
      final existingVulcan = await repo.existingVulcanNumbers();
      final results = classifyRows(
        rows: _rawRows,
        mapping: ColumnMapping(
          headerRowIndex: _headerRowIndex,
          columnToField: _columnMapping,
        ),
        existingSerialNumbers: existingSerials,
        existingVulcanNumbers: existingVulcan,
      );
      _categoryValueMap.clear();
      _locationValueMap.clear();
      for (final r in results) {
        if (r.categoryRaw.isNotEmpty) {
          _categoryValueMap.putIfAbsent(r.categoryRaw, () => null);
        }
        if (r.locationRaw.isNotEmpty) {
          _locationValueMap.putIfAbsent(r.locationRaw, () => null);
        }
      }
      setState(() {
        _classified = results;
        _step = _WizardStep.review;
      });
    } catch (e) {
      setState(() => _error = 'Blad podczas sprawdzania bazy: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final locationRepo = ref.read(locationRepositoryProvider);
      final existingCategories = ref.read(categoriesProvider).value ?? [];

      final resolvedCategoryIds = <String, String>{};
      for (final entry in _categoryValueMap.entries) {
        if (entry.value != null) {
          resolvedCategoryIds[entry.key] = entry.value!;
        } else {
          final id = _slugify(entry.key);
          await categoryRepo.upsertCategory(
            Category(
              id: id,
              name: entry.key,
              sortOrder: existingCategories.length + resolvedCategoryIds.length,
            ),
          );
          resolvedCategoryIds[entry.key] = id;
        }
      }

      final resolvedLocationIds = <String, String>{};
      for (final entry in _locationValueMap.entries) {
        if (entry.value != null) {
          resolvedLocationIds[entry.key] = entry.value!;
        } else {
          final id = await locationRepo.upsertLocation(
            Location(id: '', name: entry.key),
          );
          resolvedLocationIds[entry.key] = id;
        }
      }

      final now = DateTime.now();
      final toCreate = <Asset>[];
      var skipped = 0;
      for (final row in _classified) {
        if (!row.include) {
          skipped++;
          continue;
        }
        final categoryId = row.categoryRaw.isEmpty
            ? 'inne'
            : resolvedCategoryIds[row.categoryRaw] ?? 'inne';
        final locationId = row.locationRaw.isEmpty
            ? ''
            : (resolvedLocationIds[row.locationRaw] ?? '');
        toCreate.add(
          Asset(
            id: '',
            assetTag: _generateAssetTag(),
            categoryId: categoryId,
            name: row.name,
            manufacturer: row.values[ImportField.manufacturer],
            serialNumber: row.serialNumber.isEmpty ? null : row.serialNumber,
            vulcanNumber: row.vulcanNumber.isEmpty ? null : row.vulcanNumber,
            locationId: locationId,
            notes: row.values[ImportField.notes] ?? '',
            createdAt: now,
            updatedAt: now,
            createdBy: 'import',
            updatedBy: 'import',
          ),
        );
      }

      final repo = ref.read(importRepositoryProvider);
      final summary = await repo.commitImport(
        assetsToCreate: toCreate,
        fileName: _fileName ?? 'import',
        importedBy: 'current-user',
        skippedCount: skipped,
      );
      setState(() {
        _summary = summary;
        _step = _WizardStep.done;
      });
    } catch (e) {
      setState(() => _error = 'Blad podczas zapisu: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    const from = 'ąćęłńóśźż ';
    const to = 'acelnoszz-';
    var out = lower.split('').map((ch) {
      final idx = from.indexOf(ch);
      return idx >= 0 ? to[idx] : ch;
    }).join();
    out = out
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return out.isEmpty
        ? 'kategoria-${DateTime.now().millisecondsSinceEpoch}'
        : out;
  }

  int _tagCounter = 0;
  String _generateAssetTag() {
    _tagCounter++;
    return 'IMP${DateTime.now().millisecondsSinceEpoch}$_tagCounter'
        .substring(0, 12)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import z pliku')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(child: _buildStepBody()),
                ],
              ),
            ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case _WizardStep.pickFile:
        return _PickFileStep(onPick: _pickFile);
      case _WizardStep.mapColumns:
        return _MapColumnsStep(
          fileName: _fileName ?? '',
          isExcel: _isExcel,
          sheetNames: _sheetNames,
          selectedSheet: _selectedSheet,
          onSheetChanged: (sheet) {
            setState(() {
              _selectedSheet = sheet;
              _loadExcelSheet(sheet);
            });
          },
          rawRows: _rawRows,
          headerRowIndex: _headerRowIndex,
          columnCount: _columnCount,
          headerCells: _headerCells,
          onHeaderRowChanged: (i) => setState(() {
            _headerRowIndex = i;
            _columnMapping = {};
          }),
          columnMapping: _columnMapping,
          onMappingChanged: (col, field) =>
              setState(() => _columnMapping[col] = field),
          onNext: _runClassification,
        );
      case _WizardStep.review:
        return _ReviewStep(
          results: _classified,
          categoryValueMap: _categoryValueMap,
          locationValueMap: _locationValueMap,
          onCategoryMapped: (raw, id) =>
              setState(() => _categoryValueMap[raw] = id),
          onLocationMapped: (raw, id) =>
              setState(() => _locationValueMap[raw] = id),
          onToggleRow: (row) => setState(() => row.include = !row.include),
          onConfirm: _commit,
        );
      case _WizardStep.done:
        return _DoneStep(summary: _summary);
    }
  }
}

class _PickFileStep extends StatelessWidget {
  final VoidCallback onPick;

  const _PickFileStep({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.upload_file, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Wybierz plik CSV lub XLSX z eksportem sprzetu\n(np. z Inwentarza Optivum/Vulcan albo listy dostawy).',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open),
            label: const Text('Wybierz plik'),
          ),
        ],
      ),
    );
  }
}

class _MapColumnsStep extends StatelessWidget {
  final String fileName;
  final bool isExcel;
  final List<String> sheetNames;
  final String? selectedSheet;
  final ValueChanged<String> onSheetChanged;
  final List<List<String>> rawRows;
  final int headerRowIndex;
  final int columnCount;
  final List<String> headerCells;
  final ValueChanged<int> onHeaderRowChanged;
  final Map<int, ImportField> columnMapping;
  final void Function(int column, ImportField field) onMappingChanged;
  final VoidCallback onNext;

  const _MapColumnsStep({
    required this.fileName,
    required this.isExcel,
    required this.sheetNames,
    required this.selectedSheet,
    required this.onSheetChanged,
    required this.rawRows,
    required this.headerRowIndex,
    required this.columnCount,
    required this.headerCells,
    required this.onHeaderRowChanged,
    required this.columnMapping,
    required this.onMappingChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final previewRowsCount = rawRows.length < 8 ? rawRows.length : 8;
    return ListView(
      children: [
        Text('Plik: $fileName', style: Theme.of(context).textTheme.titleMedium),
        if (isExcel && sheetNames.length > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedSheet,
            decoration: const InputDecoration(labelText: 'Arkusz'),
            items: sheetNames
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (s) {
              if (s != null) onSheetChanged(s);
            },
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Ktory wiersz jest naglowkiem kolumn?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        DropdownButtonFormField<int>(
          initialValue: headerRowIndex,
          items: List.generate(previewRowsCount, (i) => i)
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text('Wiersz ${i + 1}: ${rawRows[i].join(' | ')}'),
                ),
              )
              .toList(),
          onChanged: (i) {
            if (i != null) onHeaderRowChanged(i);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Mapowanie kolumn',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (var col = 0; col < columnCount; col++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    col < headerCells.length && headerCells[col].isNotEmpty
                        ? headerCells[col]
                        : '(kolumna ${col + 1})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<ImportField>(
                    initialValue: columnMapping[col] ?? ImportField.skip,
                    isDense: true,
                    items: ImportField.values
                        .map(
                          (f) =>
                              DropdownMenuItem(value: f, child: Text(f.label)),
                        )
                        .toList(),
                    onChanged: (f) {
                      if (f != null) onMappingChanged(col, f);
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onNext,
          child: const Text('Dalej: sprawdz dane'),
        ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  final List<ImportRowResult> results;
  final Map<String, String?> categoryValueMap;
  final Map<String, String?> locationValueMap;
  final void Function(String raw, String? id) onCategoryMapped;
  final void Function(String raw, String? id) onLocationMapped;
  final void Function(ImportRowResult row) onToggleRow;
  final VoidCallback onConfirm;

  const _ReviewStep({
    required this.results,
    required this.categoryValueMap,
    required this.locationValueMap,
    required this.onCategoryMapped,
    required this.onLocationMapped,
    required this.onToggleRow,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final locations = ref.watch(locationsProvider).value ?? [];

    final counts = <ImportRowStatus, int>{};
    for (final r in results) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }

    return ListView(
      children: [
        Text(
          'Znaleziono ${results.length} wierszy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text('Nowe: ${counts[ImportRowStatus.newRecord] ?? 0}'),
            ),
            Chip(
              label: Text(
                'Duplikaty: ${counts[ImportRowStatus.duplicateExact] ?? 0}',
              ),
            ),
            Chip(
              label: Text(
                'Konflikty: ${counts[ImportRowStatus.conflict] ?? 0}',
              ),
            ),
            Chip(label: Text('Bledy: ${counts[ImportRowStatus.invalid] ?? 0}')),
          ],
        ),
        if (categoryValueMap.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Dopasuj kategorie',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final raw in categoryValueMap.keys)
            _ValueMappingRow(
              raw: raw,
              options: {for (final c in categories) c.id: c.name},
              selected: categoryValueMap[raw],
              onChanged: (id) => onCategoryMapped(raw, id),
            ),
        ],
        if (locationValueMap.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Dopasuj pomieszczenia',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final raw in locationValueMap.keys)
            _ValueMappingRow(
              raw: raw,
              options: {for (final l in locations) l.id: l.displayName},
              selected: locationValueMap[raw],
              onChanged: (id) => onLocationMapped(raw, id),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Wiersze (odznacz, zeby pominac)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final row in results)
          CheckboxListTile(
            dense: true,
            value: row.include,
            onChanged: (_) => onToggleRow(row),
            title: Text(
              '${row.name.isEmpty ? '(brak nazwy)' : row.name} — ${row.serialNumber}',
            ),
            subtitle: Text(
              '${_statusLabel(row.status)}${row.issue != null ? ': ${row.issue}' : ''}',
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('Importuj zaznaczone'),
        ),
      ],
    );
  }

  String _statusLabel(ImportRowStatus status) => switch (status) {
    ImportRowStatus.newRecord => 'Nowy',
    ImportRowStatus.duplicateExact => 'Duplikat',
    ImportRowStatus.conflict => 'Konflikt',
    ImportRowStatus.invalid => 'Blad',
  };
}

class _ValueMappingRow extends StatelessWidget {
  final String raw;
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _ValueMappingRow({
    required this.raw,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(raw, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String?>(
              initialValue: selected,
              isDense: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Utworz nowe'),
                ),
                ...options.entries.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  final ImportSummary? summary;

  const _DoneStep({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            summary == null
                ? 'Gotowe.'
                : 'Dodano: ${summary!.added}\nPominieto: ${summary!.skipped}\nBledy: ${summary!.failed}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zakoncz'),
          ),
        ],
      ),
    );
  }
}
