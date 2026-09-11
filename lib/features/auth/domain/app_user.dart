import 'package:cloud_firestore/cloud_firestore.dart';

enum AppRole { admin, editor, viewer }

class AppUser {
  final String uid;
  final String? displayName;
  final String email;
  final AppRole role;

  const AppUser({
    required this.uid,
    this.displayName,
    required this.email,
    this.role = AppRole.viewer,
  });

  bool get canEdit => role == AppRole.admin || role == AppRole.editor;
  bool get isAdmin => role == AppRole.admin;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String? ?? '',
      role: AppRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => AppRole.viewer,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'role': role.name,
      };
}
