import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;

class SpreadsheetParser {
  /// Parsuje CSV do siatki tekstu. Polskie eksporty (np. z Inwentarza
  /// Optivum/Vulcan) czesto sa w Windows-1250 zamiast UTF-8 - probujemy
  /// UTF-8 (z BOM), a przy bledzie kodowania spadamy do Latin-1 jako
  /// przyblizenia (moze zle wyswietlic polskie znaki - w takiej sytuacji
  /// lepiej poprosic o ponowny eksport w UTF-8).
  static List<List<String>> parseCsv(Uint8List bytes) {
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes);
    }
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    final rows = const CsvToListConverter(shouldParseNumbers: false).convert(text);
    return rows.map((row) => row.map((cell) => cell.toString()).toList()).toList();
  }

  /// Zwraca nazwy arkuszy w pliku XLSX (do wyboru przez uzytkownika, gdy
  /// plik ma ich wiele - jak w typowym eksporcie z wielu budynkow/sal).
  static List<String> listExcelSheets(Uint8List bytes) {
    final excel = xls.Excel.decodeBytes(bytes);
    return excel.tables.keys.toList();
  }

  /// Parsuje wskazany arkusz XLSX do siatki tekstu. Komorki liczbowe
  /// (np. numer seryjny zamieniony przez Excel na liczbe) sa formatowane
  /// bez zbednego ".0", ale UWAGA: jesli oryginalny numer seryjny mial
  /// wiodace zera lub litery, ta informacja mogla juz zostac utracona po
  /// stronie Excela przed eksportem - to trzeba zweryfikowac recznie.
  static List<List<String>> parseExcelSheet(Uint8List bytes, String sheetName) {
    final excel = xls.Excel.decodeBytes(bytes);
    final table = excel.tables[sheetName];
    if (table == null) return const [];
    return table.rows.map((row) {
      return row.map((cell) {
        final value = cell?.value;
        if (value == null) return '';
        if (value is xls.DoubleCellValue) {
          final d = value.value;
          return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
        }
        if (value is xls.IntCellValue) return value.value.toString();
        return value.toString();
      }).toList();
    }).toList();
  }

  /// Zgaduje wiersz naglowka: pierwszy wiersz z co najmniej dwiema
  /// niepustymi komorkami. Realne pliki (np. eksport KPO) czesto maja
  /// przed naglowkiem wiersze tytulowe/puste.
  static int guessHeaderRow(List<List<String>> rows) {
    for (var i = 0; i < rows.length; i++) {
      final nonEmpty = rows[i].where((c) => c.trim().isNotEmpty).length;
      if (nonEmpty >= 2) return i;
    }
    return 0;
  }
}
