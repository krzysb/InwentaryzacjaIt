import 'import_models.dart';

/// Klasyfikuje surowe wiersze pliku wg mapowania kolumn i zbioru juz
/// istniejacych numerow seryjnych/Vulcan w bazie. Czysta funkcja (bez
/// Firestore), dzieki czemu da sie ja przetestowac jednostkowo na
/// przykladowych, "bałaganiarskich" danych.
List<ImportRowResult> classifyRows({
  required List<List<String>> rows,
  required ColumnMapping mapping,
  required Set<String> existingSerialNumbers,
  required Set<String> existingVulcanNumbers,
}) {
  final results = <ImportRowResult>[];
  final seenInFileSerials = <String>{};

  for (var i = mapping.headerRowIndex + 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.every((cell) => cell.trim().isEmpty)) continue;

    final values = <ImportField, String>{};
    mapping.columnToField.forEach((columnIndex, field) {
      if (field == ImportField.skip) return;
      if (columnIndex >= row.length) return;
      final raw = row[columnIndex].trim();
      if (raw.isEmpty) return;
      if (field == ImportField.model && values.containsKey(ImportField.name)) {
        values[ImportField.name] = '${values[ImportField.name]} $raw'.trim();
      } else if (field == ImportField.model) {
        values[ImportField.name] = raw;
      } else {
        values[field] = raw;
      }
    });

    final name = values[ImportField.name] ?? '';
    final serial = values[ImportField.serialNumber] ?? '';
    final vulcan = values[ImportField.vulcanNumber] ?? '';

    if (name.isEmpty && serial.isEmpty) {
      // Wiersz bez nazwy i bez numeru seryjnego - najczesciej smiec
      // (pusta linia, naglowek podsekcji itp.), pomijamy bez pokazywania
      // jako blad.
      continue;
    }

    ImportRowStatus status;
    String? issue;

    if (name.isEmpty) {
      status = ImportRowStatus.invalid;
      issue = 'Brak nazwy sprzetu';
    } else if (serial.isNotEmpty && seenInFileSerials.contains(serial)) {
      status = ImportRowStatus.conflict;
      issue = 'Powielony numer seryjny w tym samym pliku';
    } else if (serial.isNotEmpty && existingSerialNumbers.contains(serial)) {
      status = ImportRowStatus.duplicateExact;
      issue = 'Sprzet o tym numerze seryjnym juz jest w bazie';
    } else if (vulcan.isNotEmpty && existingVulcanNumbers.contains(vulcan)) {
      status = ImportRowStatus.conflict;
      issue = 'Numer Vulcan juz przypisany do innego rekordu w bazie';
    } else {
      status = ImportRowStatus.newRecord;
    }

    if (serial.isNotEmpty) seenInFileSerials.add(serial);

    results.add(ImportRowResult(
      sourceRowIndex: i,
      values: values,
      status: status,
      issue: issue,
    ));
  }

  return results;
}
