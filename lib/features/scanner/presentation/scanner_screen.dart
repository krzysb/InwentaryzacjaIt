import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Tryb skanera:
/// - [findAsset]: skan wlasnego QR (assetTag) sprzetu -> przejscie do szczegolow.
/// - [fillField]: skan numeru seryjnego/kodu kreskowego producenta -> zwraca
///   zeskanowany tekst do wywolujacego ekranu (np. formularza dodawania).
enum ScannerMode { findAsset, fillField }

class ScannerScreen extends StatefulWidget {
  final ScannerMode mode;
  final String title;

  const ScannerScreen({
    super.key,
    required this.mode,
    this.title = 'Skanuj kod',
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                widget.mode == ScannerMode.findAsset
                    ? 'Zeskanuj etykiete QR na sprzecie'
                    : 'Zeskanuj kod kreskowy/QR z numerem seryjnym producenta',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
