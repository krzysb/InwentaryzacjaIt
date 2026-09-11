import 'package:flutter_test/flutter_test.dart';
import 'package:inwentaryzacja_it/features/import_export/domain/classify_rows.dart';
import 'package:inwentaryzacja_it/features/import_export/domain/import_models.dart';

void main() {
  // Uklad kolumn odzwierciedlajacy realny plik uzytkownika (arkusz "Sucha
  // Szkola" eksportu KPO): dwa wiersze tytulowe/puste przed naglowkiem,
  // kolumny Nazwa/Marka/Model/Nr seryjny/Sala/Ilosc.
  final rows = [
    ['', '', '', '', '', ''],
    ['', 'Sucha Beskidzka', '', '', '', ''],
    ['', 'Nazwa sprzetu', 'Marka', 'Model', 'Nr seryjny', 'Sala'],
    [
      '',
      'Laptop',
      'Acer',
      'Extensa 15',
      'NXEJCEP0075300C77A3400',
      'Rewalidacja Dorota Polak',
    ],
    ['', 'Laptop', 'Acer', 'Extensa 15', 'NXEJCEP0075300C28D3400', '115'],
    ['', 'Laptop', 'Acer', 'Extensa 15', 'NXEJCEP0075300B6C43400', 'P5'],
    ['', '', '', '', '', ''], // pusty wiersz - do pominiecia
    [
      '',
      'Laptop',
      'Acer',
      'Extensa 15',
      'NXEJCEP0075300C77A3400',
      'P6',
    ], // duplikat nr seryjnego w tym samym pliku
  ];

  final mapping = ColumnMapping(
    headerRowIndex: 2,
    columnToField: {
      1: ImportField.name,
      2: ImportField.manufacturer,
      3: ImportField.model,
      4: ImportField.serialNumber,
      5: ImportField.location,
    },
  );

  test('wykrywa poprawny wiersz naglowka', () {
    expect(mapping.headerRowIndex, 2);
  });

  test(
    'pomija wiersze tytulowe i puste, laczy nazwe z modelem, producenta trzyma osobno',
    () {
      final results = classifyRows(
        rows: rows,
        mapping: mapping,
        existingSerialNumbers: {},
        existingVulcanNumbers: {},
      );
      // 4 wiersze z danymi (bez pustego), z czego jeden to duplikat wewnatrz pliku
      expect(results.length, 4);
      expect(results.first.name, 'Laptop Extensa 15');
      expect(results.first.values[ImportField.manufacturer], 'Acer');
    },
  );

  test('oznacza sprzet juz istniejacy w bazie jako duplikat', () {
    final results = classifyRows(
      rows: rows,
      mapping: mapping,
      existingSerialNumbers: {'NXEJCEP0075300C28D3400'},
      existingVulcanNumbers: {},
    );
    final match = results.firstWhere(
      (r) => r.serialNumber == 'NXEJCEP0075300C28D3400',
    );
    expect(match.status, ImportRowStatus.duplicateExact);
    expect(match.include, isFalse);
  });

  test('oznacza powtorzony w pliku numer seryjny jako konflikt', () {
    final results = classifyRows(
      rows: rows,
      mapping: mapping,
      existingSerialNumbers: {},
      existingVulcanNumbers: {},
    );
    final duplicatesInFile = results
        .where((r) => r.serialNumber == 'NXEJCEP0075300C77A3400')
        .toList();
    expect(duplicatesInFile.length, 2);
    expect(duplicatesInFile.first.status, ImportRowStatus.newRecord);
    expect(duplicatesInFile.last.status, ImportRowStatus.conflict);
  });

  test(
    'pole "Sala" z nazwiskiem trafia do lokalizacji surowej bez zgadywania',
    () {
      final results = classifyRows(
        rows: rows,
        mapping: mapping,
        existingSerialNumbers: {},
        existingVulcanNumbers: {},
      );
      final withPerson = results.firstWhere(
        (r) => r.serialNumber == 'NXEJCEP0075300C77A3400',
      );
      expect(withPerson.locationRaw, 'Rewalidacja Dorota Polak');
    },
  );
}
