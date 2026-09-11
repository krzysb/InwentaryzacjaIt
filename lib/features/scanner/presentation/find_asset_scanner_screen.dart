import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../assets/presentation/providers/asset_providers.dart';
import 'scanner_screen.dart';

/// Laczy skaner w trybie "znajdz sprzet" z wyszukaniem rekordu po assetTag
/// i przejsciem do jego szczegolow.
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
    final asset = await ref.read(assetRepositoryProvider).findByAssetTag(tag);
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
