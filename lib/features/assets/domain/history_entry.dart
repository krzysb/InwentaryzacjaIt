import 'package:cloud_firestore/cloud_firestore.dart';

enum HistoryEntryType { locationChange, statusChange, edit }

class HistoryEntry {
  final String id;
  final HistoryEntryType type;
  final String? fromValue;
  final String? toValue;
  final DateTime changedAt;
  final String changedBy;
  final String? note;

  const HistoryEntry({
    required this.id,
    required this.type,
    this.fromValue,
    this.toValue,
    required this.changedAt,
    required this.changedBy,
    this.note,
  });

  factory HistoryEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HistoryEntry(
      id: doc.id,
      type: HistoryEntryType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => HistoryEntryType.edit,
      ),
      fromValue: data['fromValue'] as String?,
      toValue: data['toValue'] as String?,
      changedAt: (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changedBy: data['changedBy'] as String? ?? '',
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'fromValue': fromValue,
        'toValue': toValue,
        'changedAt': Timestamp.fromDate(changedAt),
        'changedBy': changedBy,
        'note': note,
      };
}
