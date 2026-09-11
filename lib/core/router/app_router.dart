import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/presentation/screens/asset_detail_screen.dart';
import '../../features/assets/presentation/screens/asset_form_screen.dart';
import '../../features/assets/presentation/screens/asset_list_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/import_export/presentation/import_wizard_screen.dart';
import '../../features/labels/presentation/labels_screen.dart';
import '../../features/scanner/presentation/find_asset_scanner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/assets',
    redirect: (context, state) {
      final loggedIn = authState.value != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/assets';
      return null;
    },
    refreshListenable: _AuthRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const AssetListScreen(),
      ),
      GoRoute(
        path: '/assets/new',
        builder: (context, state) => const AssetFormScreen(),
      ),
      GoRoute(
        path: '/assets/:id',
        builder: (context, state) =>
            AssetDetailScreen(assetId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assets/:id/edit',
        builder: (context, state) =>
            AssetFormScreen(assetId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/scan-find',
        builder: (context, state) => const FindAssetScannerScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportWizardScreen(),
      ),
      GoRoute(
        path: '/labels',
        builder: (context, state) => const LabelsScreen(),
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}
