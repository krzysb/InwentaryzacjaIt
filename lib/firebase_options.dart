// Plik wygenerowany automatycznie przez `flutterfire configure`.
//
// TEN PLIK JEST SZKIELETEM Z PLACEHOLDERAMI. Przed pierwszym uruchomieniem
// aplikacji nalezy go nadpisac prawdziwa konfiguracja:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure --project=<id-projektu-firebase>
// Polecenie samo utworzy projekt/aplikacje w Firebase (jesli trzeba) i
// nadpisze ten plik poprawnymi kluczami. Patrz README.md, sekcja
// "Konfiguracja Firebase".

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions nie sa skonfigurowane dla web. '
        'Uruchom `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions nie sa skonfigurowane dla tej platformy. '
          'Uruchom `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    iosBundleId: 'pl.inwentaryzacjait.inwentaryzacjaIt',
  );
}
