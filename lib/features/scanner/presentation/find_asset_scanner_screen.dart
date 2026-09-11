import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../assets/presentation/providers/asset_providers.dart';
import 'scanner_screen.dart';

/// Laczy skaner w trybie "znajdz sprzet" z wyszukaniem rekordu i przejsciem
/// do jego szczegolow. Szuka najpierw po wlasnym assetTag (nasza naklejka
/// QR), a gdy nie znajdzie - po numerze seryjnym producenta, bo wiekszy
/// wiekszosc juz zinwentaryzowanego sprzetu ma na razie tylko oryginalna
/// etykiete producenta, a nie nasza wydrukowana etykiete QR.
class FindAssetScannerScreen extends ConsumerStatefulWidget {
  const FindAssetScannerScreen({super.key});

  @override
  ConsumerState<FindAssetScannerScreen> createState() =>
      _FindAssetScannerScreenState();
}

class _FindAssetScannerScreenState
    extends ConsumerState<FindAssetScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    final tag = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(
          mode: ScannerMode.findAsset,
          title: 'Znajdz sprzet',
        ),
      ),
    );
    if (!mounted) return;
    if (tag == null) {
      context.pop();
      return;
    }
    final repo = ref.read(assetRepositoryProvider);
    final asset =
        await repo.findByAssetTag(tag) ?? await repo.findBySerialNumber(tag);
    if (!mounted) return;
    if (asset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono sprzetu o tym kodzie.')),
      );
      context.pop();
      return;
    }
    context.go('/assets/${asset.id}');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
