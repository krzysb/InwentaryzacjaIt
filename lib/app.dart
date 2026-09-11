import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/dictionaries/presentation/dictionary_providers.dart';

// Zapobiega wielokrotnemu odpalaniu seedowania w tym samym procesie -
// seedDefaultsIfEmpty() samo w sobie jest bezpieczne do powtorzenia
// (sprawdza czy kolekcja jest pusta), to tylko oszczedza zbedne odczyty.
bool _defaultCategoriesSeedAttempted = false;

class InwentaryzacjaApp extends ConsumerWidget {
  const InwentaryzacjaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Pierwsze logujace sie konto administratora automatycznie wypelnia
    // pusta kolekcje kategorii domyslnym zestawem sprzetu IT, zeby dalo
    // sie od razu dodawac sprzet bez recznego siedzenia w konsoli Firebase.
    ref.listen<AsyncValue<AppUser?>>(appUserProvider, (previous, next) {
      final user = next.value;
      if (user != null && user.isAdmin && !_defaultCategoriesSeedAttempted) {
        _defaultCategoriesSeedAttempted = true;
        ref.read(categoryRepositoryProvider).seedDefaultsIfEmpty();
      }
    });

    return MaterialApp.router(
      title: 'Inwentaryzacja IT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
