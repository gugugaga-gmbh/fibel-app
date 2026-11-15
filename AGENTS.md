# AGENTS.md – Leitfaden für Entwickler & KI-Agenten

Dieses Dokument beschreibt Architektur, Konventionen und verbindliche Regeln für
die **Fips & Fina – Fibel-App** (Flutter, Android & iOS). **Alle KI-Agenten, die
in diesem Repository arbeiten, müssen diese Regeln einhalten.**

## 1. Grundsätze

- **Erst klären, dann bauen:** Bei unklaren Anforderungen (z. B. pädagogische
  Reihenfolge, neue Module, Store-Themen) vor der Umsetzung Rückfragen stellen.
- **Quellcode ist die einzige Wahrheit:** Den aktuellen Stand immer aus den
  Dateien ableiten, nicht aus früheren Gesprächen oder Annahmen.
- **Zielgruppe Erstklässler (6–7 Jahre):** Große Touch-Flächen (min. 48 dp,
  besser 56 dp+), kurze Texte, Audio-Unterstützung für jede Anweisung, kein
  Frust durch zu strenge Bewertung.

## 2. Datenschutz & Kinderschutz (nicht verhandelbar)

- **100 % offline:** Keine Netzwerkaufrufe zur Laufzeit. Keine Analytics, keine
  Werbung, keine Crash-Reporter, keine Accounts/Logins.
- **Keine Pakete, die zur Laufzeit Daten nachladen.** `google_fonts` darf nicht
  verwendet werden (lädt Schriften aus dem Netz) – Schriften liegen lokal in
  `assets/fonts/`.
- **Elternbereich:** Alles, was Daten löscht oder Einstellungen ändert, muss
  hinter dem `ParentalGateDialog` (Rechenaufgabe) liegen.
- Fortschritt wird ausschließlich lokal über `shared_preferences` gespeichert
  (`ProgressRepository`, Schlüssel `fibel_child_progress_v1`). Bei
  Schemaänderungen den Schlüssel versionieren (`..._v2`) und migrieren.

## 3. Marken- & Urheberrecht

- „Flex und Flora“ ist eine Marke des Westermann/Diesterweg-Verlags. Es wird nur
  das **pädagogische Prinzip** übernommen. **Keine** Namen, Figuren,
  Illustrationen, Texte oder Wortlisten aus den Original-Heften verwenden.
- Maskottchen sind die eigenen Figuren **Fips (Fuchs)** und **Fina (Eule)**
  (`lib/core/widgets/mascot_widget.dart`).
- Schriftart **Andika** steht unter der SIL Open Font License 1.1. Der
  Lizenztext liegt in `assets/fonts/OFL.txt`, wird mit der App gebündelt und in
  `main.dart` über `LicenseRegistry` registriert – nicht entfernen.

## 4. Architektur

```
lib/
├── main.dart                     # ProviderScope + GoRouter (Routen)
├── core/
│   ├── audio/                    # AudioService (flutter_tts, de-DE)
│   ├── curriculum/               # Modelle + Laden von curriculum_de.json
│   ├── storage/                  # ProgressRepository / ProgressNotifier
│   ├── theme/                    # AppColors, AppTheme (Andika)
│   └── widgets/                  # SyllableTextWidget, MascotBanner, ParentalGateDialog
└── features/
    ├── home/                     # Lernwelt mit Buchstaben-Karten
    ├── phonics/                  # Modul 1: Anlauttabelle & Laut-Zug
    ├── writing/                  # Modul 2: Nachspuren im Dreilinien-Haus + StrokeValidator
    ├── syllables/                # Modul 3: Silbenbögen & Silbenteppich
    ├── reading/                  # Modul 4: Silben-Puzzle & erste Sätze
    └── rewards/                  # Modul 5: Sticker-Album & Elternbereich
```

- **State Management:** `flutter_riverpod` (2.x, `StateNotifierProvider`,
  `FutureProvider`).
- **Navigation:** `go_router`. Lektionen werden als `extra` (`LessonUnit`) an
  die Modul-Routen `/unit/:id/{phonics|tracing|syllables|reading}` übergeben.
- **Imports:** In Flutter ≥ 3.47 ist `package:flutter/material.dart` veraltet.
  Immer `package:material_ui/material_ui.dart` verwenden.

## 5. Curriculum (`assets/data/curriculum_de.json`)

- **Neue Inhalte immer hier pflegen, nicht im Dart-Code.**
- Lektionen (`units`) werden nach `order` sortiert. Die Reihenfolge folgt dem
  Silbenprinzip: zuerst Dauerlaute und Vokale (`M, A, O, I, L, S, E …`), damit
  früh lesbare Silben/Wörter entstehen.
- **Schreibpfade** (`upperStrokes`/`lowerStrokes`): normierte Koordinaten
  `[x, y]` im Bereich `0.0–1.0`. Das Dreilinien-Haus liegt bei
  `y = 0.12` (Dach), `0.35` (Mittellinie), `0.65` (Grundlinie), `0.90` (Keller).
  Großbuchstaben: `0.12–0.65`; Kleinbuchstaben ohne Ober-/Unterlänge:
  `0.35–0.65`; Unterlängen (g, j, p) reichen bis `~0.90`.
- **Silben** (`syllables`): Silbentrennung nach deutscher Rechtschreibung. Die
  Verkettung aller Silben eines Wortes **muss exakt `fullWord` ergeben** (das
  Silben-Puzzle prüft `join() == fullWord`).
- **Silbenfärbung:** Ungerade Silben Blau (`AppColors.syllableBlue`), gerade
  Rot (`AppColors.syllableRed`) – nicht ändern.
- **Laut-Quiz** (`soundQuiz.position`): nur `start`, `middle` oder `end`.
- Nach Änderungen die Zählungen in `test/curriculum_and_stroke_test.dart`
  anpassen (aktuell 26 Lektionen, 34 Anlaute, 8 Sticker).

## 6. Tests

| Ebene | Ort | Befehl |
| --- | --- | --- |
| Unit | `test/curriculum_and_stroke_test.dart` | `flutter test` |
| Widget | `test/widget_test.dart` | `flutter test` |
| E2E | `integration_test/app_e2e_test.dart` | `flutter test integration_test -d <device>` |

- Vor jedem Commit: `flutter analyze` (0 Issues) und `flutter test` müssen grün
  sein.
- **Asset-Laden in Tests:** `rootBundle` lädt echte I/O. Nach `pumpWidget` immer
  `await tester.runAsync(() => Future.delayed(...))` vor `pumpAndSettle()`.
- **Endlos-Animationen:** Der Nachspur-Bildschirm hat eine pulsierende
  Animation (`repeat`). Dort **kein** `pumpAndSettle()`, sondern
  `pump(Duration)` verwenden – sonst Timeout.
- E2E-Tests brauchen ein echtes Gerät oder einen Emulator (läuft nicht auf
  `linux`/`chrome`, da nur Android/iOS als Plattformen angelegt sind).

## 7. CI/CD (ausschließlich GitLab CI)

- Pipeline: `.gitlab-ci.yml` mit den Stages `analyze → test → e2e → build`.
- **Keine GitHub-Actions-Workflows anlegen** (`.github/workflows/` wurde bewusst
  entfernt).
- Image: `ghcr.io/cirruslabs/flutter:stable`.
- Der Job `e2e_android_emulator` startet einen Headless-Emulator
  (`android-34`, x86_64). **Er benötigt einen Runner mit KVM-Unterstützung**
  (`/dev/kvm`); auf Standard-Shared-Runnern ohne KVM schlägt er fehl oder ist
  extrem langsam.

## 8. Bekannte offene Punkte

- `just_audio` steht in `pubspec.yaml`, wird aber noch nicht genutzt – es ist
  für künftige Phonem-Aufnahmen (`assets/audio/phonemes/`) vorgesehen.
- Einzellaute werden derzeit per TTS gesprochen und klingen teils wie
  Buchstabennamen. Ziel: echte Lautaufnahmen.
- Kein iOS-Build-Job in der Pipeline (benötigt macOS-Runner).
