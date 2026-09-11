import 'package:cloud_firestore/cloud_firestore.dart';

import '../../assets/domain/asset.dart';
import '../domain/import_models.dart';

class ImportRepository {
  final FirebaseFirestore _firestore;

  ImportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Set<String>> existingSerialNumbers() async {
    final snapshot = await _firestore.collection('assets').get();
    return snapshot.docs
        .map((d) => d.data()['serialNumber'] as String?)
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  Future<Set<String>> existingVulcanNumbers() async {
    final snapshot = await _firestore.collection('assets').get();
    return snapshot.docs
        .map((d) => d.data()['vulcanNumber'] as String?)
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  /// Zapisuje zaakceptowane wiersze partiami (limit 500 operacji/batch w
  /// Firestore) i tworzy rekord importBatches z podsumowaniem - przydatny
  /// przy porzadkowaniu bałaganu, zeby wiedziec skad dany rekord pochodzi.
  Future<ImportSummary> commitImport({
    required List<Asset> assetsToCreate,
    required String fileName,
    required String importedBy,
    required int skippedCount,
  }) async {
    const chunkSize = 450;
    var added = 0;
    var failed = 0;
    final batchId = _firestore.collection('importBatches').doc().id;

    for (var start = 0; start < assetsToCreate.length; start += chunkSize) {
      final chunk = assetsToCreate.sublist(
        start,
        start + chunkSize > assetsToCreate.length
            ? assetsToCreate.length
            : start + chunkSize,
      );
      final batch = _firestore.batch();
      for (final asset in chunk) {
        final docRef = _firestore.collection('assets').doc();
        batch.set(docRef, asset.copyWith(importBatchId: batchId).toFirestore());
      }
      try {
        await batch.commit();
        added += chunk.length;
      } catch (_) {
        failed += chunk.length;
      }
    }

    await _firestore.collection('importBatches').doc(batchId).set({
      'fileName': fileName,
      'importedAt': Timestamp.now(),
      'importedBy': importedBy,
      'rowCount': assetsToCreate.length,
      'added': added,
      'skipped': skippedCount,
      'failed': failed,
    });

    return ImportSummary(added: added, skipped: skippedCount, failed: failed);
  }
}
