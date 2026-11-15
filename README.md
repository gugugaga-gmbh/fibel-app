# Fips & Fina – Fibel-App

Flutter-Lern-App (Android & iOS) für Erstklässler zum Lesen- und
Schreibenlernen nach dem **Silben- und Anlautprinzip** – 100 % offline, ohne
Login, ohne Werbung.

> Die App orientiert sich am pädagogischen Ansatz silbenbasierter
> Erstlese-Lehrgänge (z. B. „Flex und Flora“), verwendet aber ausschließlich
> eigene Figuren, Wörter und Inhalte.

## Funktionen

| Modul | Inhalt |
| --- | --- |
| 1. Laute hören | Interaktive Anlauttabelle (34 Laute) und „Laut-Zug“: Wo hörst du den Laut – Anfang, Mitte oder Ende? |
| 2. Nachspuren & Schreiben | Groß- und Kleinbuchstaben im Dreilinien-Haus (Dach, Wohnung, Keller) mit Startpunkt, Strichnummern und toleranter Prüfung |
| 3. Silben schwingen | Zweifarbige Silben (Blau/Rot) mit Silbenbögen zum Antippen, Silbenteppich |
| 4. Wörter & Sätze | Silben-Puzzle zum Wörterbauen, erste Sätze mit Vorlesefunktion |
| 5. Belohnung | Sterne, Sticker-Album, Maskottchen Fips (Fuchs) & Fina (Eule) |

- **26 Lektionen:** alle Buchstaben A–Z, Umlaute, `Sch`, `Ei`/`Au`
- **Schulschrift:** Andika (lokal eingebunden, kindgerechte `a`/`g`-Formen)
- **Sprachausgabe:** deutsche Text-to-Speech-Stimme des Geräts
- **Elternbereich:** geschützt durch eine Rechenaufgabe; Fortschritt einsehen
  und zurücksetzen

## Schnellstart

Voraussetzungen: Flutter SDK (stable, Dart ≥ 3.14), Android Studio bzw. Xcode.

```bash
git clone https://github.com/gugugaga-gmbh/fibel-app.git
cd fibel-app
flutter pub get
flutter run            # auf angeschlossenem Gerät / Emulator
```

## Tests

```bash
flutter analyze                                   # statische Analyse
flutter test                                      # Unit- & Widget-Tests
flutter test integration_test -d <device-id>      # E2E (Gerät/Emulator nötig)
```

## CI/CD (GitLab CI)

Die Pipeline in [`.gitlab-ci.yml`](.gitlab-ci.yml) läuft in vier Stages:

1. **analyze** – `flutter analyze`
2. **test** – `flutter test --coverage` (Coverage als Artefakt)
3. **e2e** – Headless-Android-Emulator (API 34) + `integration_test`
   (auf `main` und in Merge Requests; benötigt einen Runner mit KVM)
4. **build** – Release-APK als Artefakt (nur `main`)

## Inhalte erweitern

Alle Lerninhalte liegen in
[`assets/data/curriculum_de.json`](assets/data/curriculum_de.json) – neue
Wörter, Sätze oder Buchstaben werden dort ergänzt, ohne Dart-Code zu ändern.
Format und Regeln (Schreibpfade, Silbentrennung, Reihenfolge) sind in
[`AGENTS.md`](AGENTS.md) beschrieben.

## Projektstruktur

```
assets/            Curriculum (JSON) und Schriftarten
lib/core/          Audio, Curriculum, Speicherung, Theme, gemeinsame Widgets
lib/features/      Die fünf Lernmodule + Startbildschirm
test/              Unit- und Widget-Tests
integration_test/  End-to-End-Tests
```

## Datenschutz

Die App erhebt und überträgt keine Daten. Der Lernfortschritt wird nur lokal
auf dem Gerät gespeichert.

## Lizenzen

- Schriftart **Andika**: SIL Open Font License 1.1
