/// Pole docelowe modelu Asset, na ktore mozna zmapowac kolumne z pliku.
enum ImportField {
  skip,
  name,
  manufacturer,
  model,
  serialNumber,
  vulcanNumber,
  category,
  location,
  notes;

  String get label => switch (this) {
        ImportField.skip => 'Pomin kolumne',
        ImportField.name => 'Nazwa / model',
        ImportField.manufacturer => 'Producent',
        ImportField.model => 'Model (dopisany do nazwy)',
        ImportField.serialNumber => 'Numer seryjny',
        ImportField.vulcanNumber => 'Numer z ewidencji Vulcan',
        ImportField.category => 'Kategoria',
        ImportField.location => 'Pomieszczenie',
        ImportField.notes => 'Notatki',
      };
}

/// Wynik parsowania pliku (CSV lub jeden arkusz XLSX) do prostej siatki
/// tekstu - bez zadnej interpretacji typow, zeby uniknac problemow typu
/// "Excel zamienil numer seryjny na liczbe".
class ParsedSheet {
  final String sourceName;
  final List<List<String>> rows;

  const ParsedSheet({required this.sourceName, required this.rows});

  List<String> get availableSheets => const [];
}

/// Mapowanie kolumn (po indeksie w wybranym wierszu naglowka) na pola Asset.
class ColumnMapping {
  final int headerRowIndex;
  final Map<int, ImportField> columnToField;

  const ColumnMapping({required this.headerRowIndex, required this.columnToField});
}

enum ImportRowStatus { newRecord, duplicateExact, conflict, invalid }

/// Pojedynczy sklasyfikowany wiersz z pliku, gotowy do podglądu i decyzji
/// uzytkownika przed zapisem.
class ImportRowResult {
  final int sourceRowIndex;
  final Map<ImportField, String> values;
  final ImportRowStatus status;
  final String? existingAssetId;
  final String? issue;
  bool include;

  ImportRowResult({
    required this.sourceRowIndex,
    required this.values,
    required this.status,
    this.existingAssetId,
    this.issue,
    bool? include,
  }) : include = include ?? (status != ImportRowStatus.duplicateExact);

  String get name => values[ImportField.name] ?? '';
  String get serialNumber => values[ImportField.serialNumber] ?? '';
  String get vulcanNumber => values[ImportField.vulcanNumber] ?? '';
  String get categoryRaw => values[ImportField.category] ?? '';
  String get locationRaw => values[ImportField.location] ?? '';
}

class ImportSummary {
  final int added;
  final int skipped;
  final int failed;

  const ImportSummary({required this.added, required this.skipped, required this.failed});
}
