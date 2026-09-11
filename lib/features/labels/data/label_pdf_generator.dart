import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../assets/domain/asset.dart';

/// Buduje arkusz PDF z etykietami QR do wydruku na zwyklej drukarce (na
/// samoprzylepnym papierze etykietowym A4). Kazda etykieta koduje
/// [Asset.assetTag] - to samo, co skaner w trybie "znajdz sprzet" odczytuje.
///
/// Rozmiar etykiety (70x37 mm) odpowiada popularnym arkuszom A4 na 21
/// etykiet (3 kolumny x 7 wierszy) - [pw.Wrap] sam rozklada je na strony,
/// gdy jest ich wiecej niz miesci sie na jednej.
class LabelPdfGenerator {
  static const _labelWidth = PdfPageFormat.mm * 70;
  static const _labelHeight = PdfPageFormat.mm * 37;

  static Future<Uint8List> build(List<Asset> assets) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: PdfPageFormat.mm * 5,
          marginRight: PdfPageFormat.mm * 5,
          marginTop: PdfPageFormat.mm * 10,
          marginBottom: PdfPageFormat.mm * 10,
        ),
        build: (context) => [
          pw.Wrap(
            spacing: 0,
            runSpacing: 0,
            children: assets.map(_buildLabel).toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildLabel(Asset asset) {
    return pw.Container(
      width: _labelWidth,
      height: _labelHeight,
      padding: const pw.EdgeInsets.all(4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.grey400, width: .5),
          top: pw.BorderSide(color: PdfColors.grey400, width: .5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.BarcodeWidget(
            data: asset.assetTag,
            barcode: pw.Barcode.qrCode(),
            width: _labelHeight - 8,
            height: _labelHeight - 8,
            drawText: false,
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  asset.name,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(asset.assetTag, style: const pw.TextStyle(fontSize: 7)),
                if ((asset.serialNumber ?? '').isNotEmpty)
                  pw.Text(
                    'S/N: ${asset.serialNumber}',
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey700,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
