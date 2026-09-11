# Inwentaryzacja IT

Aplikacja mobilna (Android, Flutter) do inwentaryzacji zasobow IT w szkole:
dodawanie sprzetu do bazy, sprawdzanie gdzie sie znajduje, filtrowanie po
kategoriach, skanowanie kodow QR/kreskowych oraz import danych z Excela/CSV
(np. eksportu z Inwentarza Optivum/Vulcan).

Pelny plan projektu (model danych, fazy wdrozenia) znajduje sie w historii
konwersacji, ktora zainicjowala ten projekt - ponizej skrocona instrukcja
uruchomienia tego, co juz zaimplementowano (Faza 0-1: szkielet + CRUD sprzetu,
Faza 2+: import danych, etykiety, historia - w budowie).

## Wymagania

- Flutter SDK 3.35+ (`flutter --version`)
- Konto Firebase (darmowy plan Spark wystarczy na start)
- Android Studio / Android SDK do budowania i uruchamiania na urzadzeniu/emulatorze

## Konfiguracja Firebase (wymagana przed pierwszym uruchomieniem)

Plik `lib/firebase_options.dart` w repozytorium to **szkielet z placeholderami**
(`REPLACE_WITH_FLUTTERFIRE_CONFIGURE`) - aplikacja nie uruchomi sie z nim tak,
jak jest. Trzeba go nadpisac prawdziwa konfiguracja:

1. Zaloz projekt na [console.firebase.google.com](https://console.firebase.google.com)
   (np. `inwentaryzacja-it-szkola`).
2. W projekcie wlacz: **Firestore Database** (tryb produkcyjny - reguly juz
   sa w `firestore.rules`), **Authentication** -> metoda logowania
   e-mail/haslo, **Storage** (na zdjecia sprzetu).
3. Zainstaluj narzedzia:
   ```
   dart pub global activate flutterfire_cli
   ```
4. W katalogu projektu uruchom:
   ```
   flutterfire configure --project=<id-twojego-projektu-firebase> --platforms=android
   ```
   Polecenie nadpisze `lib/firebase_options.dart` prawdziwymi kluczami i
   doda plik `android/app/google-services.json`.
5. Wdroz reguly i indeksy Firestore z repozytorium:
   ```
   firebase deploy --only firestore:rules,firestore:indexes
   ```
6. Zaloz pierwsze konto administratora: w konsoli Firebase Authentication
   dodaj uzytkownika (e-mail/haslo), a nastepnie w Firestore w kolekcji
   `users` utworz dokument o ID rownym UID tego uzytkownika z polami:
   ```json
   { "email": "twoj@email", "displayName": "Imie Nazwisko", "role": "admin" }
   ```
   Bez tego dokumentu logowanie zadziala, ale aplikacja nie przypisze roli
   (domyslnie `viewer` - tylko odczyt).

Kategorie sprzetu (`categories`) aplikacja **automatycznie** wypelni
domyslnym zestawem przy pierwszym logowaniu konta z rola `admin`, jesli
kolekcja jest pusta (patrz `app.dart` i
`CategoryRepository.seedDefaultsIfEmpty()`). Pomieszczenia (`locations`)
trzeba dodac recznie - **ale juz nie przez konsole Firebase**: w appce,
z listy sprzetu, menu (trzy kropki) -> "Slowniki" -> zakladka
"Pomieszczenia" -> przycisk "+". Bez chociaz jednego pomieszczenia
formularz dodawania sprzetu nie bedzie mial czego zaproponowac w polu
"Pomieszczenie".

## Uruchomienie

```
flutter pub get
flutter run
```

## Struktura projektu

```
lib/
  core/                 # motyw, router, wspolne widgety/utils
  features/
    auth/                # logowanie, rola uzytkownika
    assets/              # model sprzetu, CRUD, lista/szczegoly/formularz
    scanner/              # skaner QR/kodow kreskowych (2 tryby)
    dictionaries/         # kategorie i pomieszczenia (slowniki)
    labels/                # generowanie/druk etykiet QR (Faza 3, w budowie)
    import_export/         # import CSV/Excel (Faza 2, w budowie)
    duplicates/             # scalanie duplikatow (Faza 2, w budowie)
    dashboard/               # statystyki (Faza 4, w budowie)
firestore.rules          # reguly dostepu (wymagana autentykacja + role)
firestore.indexes.json   # indeksy zlozone pod filtrowanie
```

## Stan implementacji

- ✅ Logowanie (Firebase Auth, e-mail/haslo)
- ✅ Lista sprzetu z wyszukiwaniem i filtrami (kategoria/pomieszczenie/status/niekompletne)
- ✅ Szczegoly sprzetu + historia zmian lokalizacji/statusu
- ✅ Formularz dodaj/edytuj sprzet, ze skanowaniem numeru seryjnego
- ✅ Skaner w trybie "znajdz sprzet" (skan wlasnego QR -> szczegoly)
- ✅ Wykrywanie duplikatu po numerze seryjnym przy dodawaniu
- ✅ Import CSV/Excel z mapowaniem kolumn (obsluguje wiele arkuszy, dowolny wiersz naglowka,
  dopasowanie kategorii/pomieszczen, wykrywanie duplikatow/konfliktow wzgledem bazy i wewnatrz pliku)
- ✅ Generowanie i druk etykiet QR (arkusz PDF, wybor sprzetu do druku lub pojedyncza etykieta ze szczegolow)
- ✅ Filtr "niekompletne" na liscie sprzetu (odpowiednik ekranu "do uzupelnienia")
- ✅ Slowniki kategorii/pomieszczen (CRUD w UI - dodawanie/edycja/usuwanie, bez konsoli Firebase)
- ✅ Wykrywanie mozliwych duplikatow (po numerze seryjnym) i ekran scalania rekordow pole po polu
- ⏳ Role uzytkownikow w UI (admin/editor/viewer) i dashboard

## Import danych z Vulcan (Inwentarz Optivum)

Modul sprzetowy w Vulcan to **Inwentarz Optivum**. Eksport: funkcja
*Eksport srodkow trwalych* generuje liste wg numeru inwentarzowego lub kodu
kreskowego (kolumny: Nazwa srodka, Numer inwentarzowy, Miejsce uzytkowania,
itd.). Eksportowane sa tylko srodki aktywne. Docelowo plik z takiego
eksportu bedzie mozna zaimportowac przez kreator w `features/import_export`
(w budowie).
