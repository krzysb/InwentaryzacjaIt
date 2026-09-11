import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import 'auth_providers.dart';

/// Nadawanie rol (admin/editor/viewer) juz istniejacym kontom. Zakladanie
/// nowych kont zostaje recznie w konsoli Firebase (SDK klienta nie moze
/// utworzyc konta bez wylogowania biezacego uzytkownika) - patrz README.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  String _roleLabel(AppRole role) => switch (role) {
    AppRole.admin => 'Administrator',
    AppRole.editor => 'Edytor',
    AppRole.viewer => 'Tylko podglad',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Uzytkownicy i role')),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Brak uzytkownikow.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelf = user.uid == currentUid;
              return ListTile(
                title: Text(user.displayName ?? user.email),
                subtitle: Text(user.email),
                trailing: DropdownButton<AppRole>(
                  value: user.role,
                  onChanged: isSelf
                      ? null
                      : (role) {
                          if (role != null) {
                            ref
                                .read(authRepositoryProvider)
                                .updateUserRole(user.uid, role);
                          }
                        },
                  items: AppRole.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabel(r)),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nie udalo sie wczytac listy (wymagana rola administratora): $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
