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
| 1. Laute hören | Interaktive Anlauttabelle (37 Laute, Filter nach Silbenkönigen 👑, Mitlauten & Mehrgraphemen), „Laut-Zug“ und **„Reim-Detektiv“** (Reimwörter & Minimalpaare) |
| 2. Nachspuren & Schreiben | 3-stufiges Schreiben im Dreilinien-Haus (Groß, Klein & Frei schreiben, inkl. Linkshänder-Modus) sowie **Anlaut-Werkstatt** (Freies Schreiben, Wort-Rätsel & akustisches **Hör-Diktat 🎧**) |
| 3. Silben schwingen | Zweifarbige Silben (Blau/Rot) mit Silbenbögen, Silbenteppich, „Silben klatschen“ und **„Silbenkönige 👑“**-Training |
| 4. Wörter, Sätze & Geschichten | Silben-Puzzle, erste Sätze, „Satz-Rätsel“, „Blitzlesen“ sowie **Lesepass & Stufen-Geschichten** (Stufen 1–4) |
| 5. Belohnung & Urkunden | Einstellbares Tagesziel & Lern-Serie 🔥, adaptives „Tägliches Training“, **24 sprechende Sticker** und **Lese-Urkunden 🏆** für jede gemeisterte Stufe |

- **33 Lektionen in 4 Stufen:** Sanfte Stufen-Empfehlung (oder optional strikte 70-%-Regel) für alle Buchstaben A–Z, Umlaute (`Ä, Ö, Ü`) und Mehrgrapheme (`Ei, Au, Sch, Eu, Ch, St, Sp, Qu`)
- **Schulschrift & Barrierefreiheit:** Andika (lokal eingebunden, kindgerechte `a`/`g`-Formen), optional vergrößerte Leseschrift (+15 %) und erhöhter Kontrast-Modus
- **Sprachausgabe & Offline-Audio:** lautgetreue deutsche Phonetik-Abbildung, Offline-WAV-Chimes & Feier-Fanfare (Geschwindigkeit anpassbar)
- **Eltern- & Lehrkräftebereich:** geschützt durch eine Rechenaufgabe; Mehrkind-Profile, Kompetenz-Diagnostik & Förderempfehlung, kopierbarer **Lernbericht & Lese-Pass**, Offline-JSON-Backup sowie Stufen-Freischaltung

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

- Schriftart **Andika** (© SIL International): SIL Open Font License 1.1 –
  siehe [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt)
