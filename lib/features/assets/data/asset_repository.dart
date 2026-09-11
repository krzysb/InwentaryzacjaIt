import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/asset.dart';
import '../domain/asset_status.dart';
import '../domain/history_entry.dart';

class AssetFilter {
  final String? categoryId;
  final String? locationId;
  final AssetStatus? status;
  final bool onlyIncomplete;
  final String searchText;

  const AssetFilter({
    this.categoryId,
    this.locationId,
    this.status,
    this.onlyIncomplete = false,
    this.searchText = '',
  });

  AssetFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? locationId,
    bool clearLocation = false,
    AssetStatus? status,
    bool clearStatus = false,
    bool? onlyIncomplete,
    String? searchText,
  }) {
    return AssetFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      status: clearStatus ? null : (status ?? this.status),
      onlyIncomplete: onlyIncomplete ?? this.onlyIncomplete,
      searchText: searchText ?? this.searchText,
    );
  }
}

/// Repozytorium sprzetu. Filtrowanie po kategorii/lokalizacji/statusie robimy
/// zapytaniami Firestore, a wyszukiwanie tekstowe (po nazwie/numerze
/// seryjnym/numerze Vulcan/assetTag) lokalnie na juz zsynchronizowanym
/// strumieniu - dataset szkolny miesci sie w pamieci, wiec to prostsze niz
/// utrzymywanie osobnego indeksu wyszukiwania.
class AssetRepository {
  final FirebaseFirestore _firestore;

  AssetRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assets => _firestore.collection('assets');

  Stream<List<Asset>> watchAssets(AssetFilter filter) {
    Query<Map<String, dynamic>> query = _assets;
    if (filter.categoryId != null) {
      query = query.where('categoryId', isEqualTo: filter.categoryId);
    }
    if (filter.locationId != null) {
      query = query.where('locationId', isEqualTo: filter.locationId);
    }
    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }
    if (filter.onlyIncomplete) {
      query = query.where('isIncomplete', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var assets = snapshot.docs.map(Asset.fromFirestore).toList();
      final search = filter.searchText.trim().toLowerCase();
      if (search.isNotEmpty) {
        assets = assets.where((a) {
          return a.name.toLowerCase().contains(search) ||
              (a.serialNumber?.toLowerCase().contains(search) ?? false) ||
              (a.vulcanNumber?.toLowerCase().contains(search) ?? false) ||
              a.assetTag.toLowerCase().contains(search);
        }).toList();
      }
      assets.sort((a, b) => a.name.compareTo(b.name));
      return assets;
    });
  }

  Stream<Asset?> watchAsset(String id) {
    return _assets.doc(id).snapshots().map((doc) => doc.exists ? Asset.fromFirestore(doc) : null);
  }

  Future<Asset?> findBySerialNumber(String serialNumber) async {
    final snapshot = await _assets.where('serialNumber', isEqualTo: serialNumber).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return Asset.fromFirestore(snapshot.docs.first);
  }

  Future<Asset?> findByAssetTag(String assetTag) async {
    final snapshot = await _assets.where('assetTag', isEqualTo: assetTag).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return Asset.fromFirestore(snapshot.docs.first);
  }

  Future<String> createAsset(Asset asset) async {
    final doc = await _assets.add(asset.toFirestore());
    return doc.id;
  }

  Future<void> updateAsset(Asset asset) async {
    await _assets.doc(asset.id).update(asset.toFirestore());
  }

  /// Zapisuje zmiane sprzetu wraz z wpisem w historii w jednej operacji
  /// atomowej - uzywane przy przenoszeniu miedzy pomieszczeniami i zmianie
  /// statusu, zeby timeline zawsze byl spojny z aktualnym stanem rekordu.
  Future<void> updateAssetWithHistory({
    required Asset updatedAsset,
    required HistoryEntryType type,
    required String? fromValue,
    required String? toValue,
    required String changedBy,
    String? note,
  }) async {
    final batch = _firestore.batch();
    batch.update(_assets.doc(updatedAsset.id), updatedAsset.toFirestore());
    final historyRef = _assets.doc(updatedAsset.id).collection('history').doc();
    batch.set(
      historyRef,
      HistoryEntry(
        id: historyRef.id,
        type: type,
        fromValue: fromValue,
        toValue: toValue,
        changedAt: DateTime.now(),
        changedBy: changedBy,
        note: note,
      ).toFirestore(),
    );
    await batch.commit();
  }

  Stream<List<HistoryEntry>> watchHistory(String assetId) {
    return _assets
        .doc(assetId)
        .collection('history')
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HistoryEntry.fromFirestore).toList());
  }

  Future<void> deleteAsset(String id) async {
    await _assets.doc(id).delete();
  }
}
