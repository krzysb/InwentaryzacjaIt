import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/domain/asset.dart';
import '../../assets/domain/asset_status.dart';
import '../../assets/presentation/providers/asset_providers.dart';

/// Grupuje sprzet po numerze seryjnym i zwraca tylko grupy z wiecej niz
/// jednym aktywnym rekordem - to najbardziej wiarygodny sygnal duplikatu
/// (ten sam fizyczny sprzet wpisany do bazy dwa razy).
final duplicateGroupsProvider = Provider<List<List<Asset>>>((ref) {
  final assets = ref.watch(allAssetsProvider).value ?? [];
  final bySerial = <String, List<Asset>>{};
  for (final asset in assets) {
    if (asset.status == AssetStatus.wycofany) continue;
    final serial = asset.serialNumber?.trim();
    if (serial == null || serial.isEmpty) continue;
    bySerial.putIfAbsent(serial, () => []).add(asset);
  }
  return bySerial.values.where((group) => group.length > 1).toList();
});
