import 'package:cloud_firestore/cloud_firestore.dart';

import 'asset_status.dart';

class Asset {
  final String id;
  final String assetTag;
  final String categoryId;
  final String name;
  final String? manufacturer;
  final String? serialNumber;
  final String? vulcanNumber;
  final String locationId;
  final AssetStatus status;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final DateTime? warrantyUntil;
  final List<String> photoUrls;
  final String notes;
  final bool isIncomplete;
  final String? duplicateOfAssetId;
  final String? importBatchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  const Asset({
    required this.id,
    required this.assetTag,
    required this.categoryId,
    required this.name,
    this.manufacturer,
    this.serialNumber,
    this.vulcanNumber,
    required this.locationId,
    this.status = AssetStatus.sprawny,
    this.purchaseDate,
    this.purchasePrice,
    this.warrantyUntil,
    this.photoUrls = const [],
    this.notes = '',
    this.isIncomplete = false,
    this.duplicateOfAssetId,
    this.importBatchId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// Rekord uznajemy za niekompletny, gdy brakuje numeru Vulcan, numeru
  /// seryjnego lub lokalizacji - to wlasnie te braki tworza dzisiejszy balagan.
  static bool computeIsIncomplete({
    required String? serialNumber,
    required String? vulcanNumber,
    required String locationId,
  }) {
    return (serialNumber == null || serialNumber.trim().isEmpty) ||
        (vulcanNumber == null || vulcanNumber.trim().isEmpty) ||
        locationId.trim().isEmpty;
  }

  factory Asset.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Asset(
      id: doc.id,
      assetTag: data['assetTag'] as String? ?? doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      manufacturer: data['manufacturer'] as String?,
      serialNumber: data['serialNumber'] as String?,
      vulcanNumber: data['vulcanNumber'] as String?,
      locationId: data['locationId'] as String? ?? '',
      status: AssetStatus.fromName(data['status'] as String?),
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      warrantyUntil: (data['warrantyUntil'] as Timestamp?)?.toDate(),
      photoUrls: (data['photoUrls'] as List?)?.cast<String>() ?? const [],
      notes: data['notes'] as String? ?? '',
      isIncomplete: data['isIncomplete'] as bool? ?? false,
      duplicateOfAssetId: data['duplicateOfAssetId'] as String?,
      importBatchId: data['importBatchId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assetTag': assetTag,
      'categoryId': categoryId,
      'name': name,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'vulcanNumber': vulcanNumber,
      'locationId': locationId,
      'status': status.name,
      'purchaseDate': purchaseDate == null ? null : Timestamp.fromDate(purchaseDate!),
      'purchasePrice': purchasePrice,
      'warrantyUntil': warrantyUntil == null ? null : Timestamp.fromDate(warrantyUntil!),
      'photoUrls': photoUrls,
      'notes': notes,
      'isIncomplete': computeIsIncomplete(
        serialNumber: serialNumber,
        vulcanNumber: vulcanNumber,
        locationId: locationId,
      ),
      'duplicateOfAssetId': duplicateOfAssetId,
      'importBatchId': importBatchId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  Asset copyWith({
    String? assetTag,
    String? categoryId,
    String? name,
    String? manufacturer,
    String? serialNumber,
    String? vulcanNumber,
    String? locationId,
    AssetStatus? status,
    DateTime? purchaseDate,
    double? purchasePrice,
    DateTime? warrantyUntil,
    List<String>? photoUrls,
    String? notes,
    String? duplicateOfAssetId,
    String? importBatchId,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Asset(
      id: id,
      assetTag: assetTag ?? this.assetTag,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      vulcanNumber: vulcanNumber ?? this.vulcanNumber,
      locationId: locationId ?? this.locationId,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      isIncomplete: isIncomplete,
      duplicateOfAssetId: duplicateOfAssetId ?? this.duplicateOfAssetId,
      importBatchId: importBatchId ?? this.importBatchId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
