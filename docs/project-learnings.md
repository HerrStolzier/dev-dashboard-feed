# Project Learnings

## Overview

Dieses Dokument sammelt nur langlebige Learnings.
Kurzlebige To-dos oder rein momentane Zwischenstaende gehoeren nach `docs/current-status.md`.

## Stable Learnings

- Ordnerzugriff fuer die App laeuft ueber einen nativen Folder-Picker plus gespeicherte Bookmarks.
- HTML-Dateien bleiben unveraenderte Quellartefakte. Die App liest sie nur und legt Metadaten darueber.
- Ein gemeinsames Dokument-Modell ist wichtig, damit Sample-Daten und echte Dateien denselben UI-Pfad verwenden.
- Solange keine beobachteten Ordner konfiguriert sind, bleibt der Sample-Modus als ruhiger Fallback sinnvoll.
- Die aktuelle Scanner-Logik ist absichtlich konservativ. Erklaerbaer-Erkennung sollte nicht zu breit werden, sonst entstehen falsche Highlights.
- Fuer lokale HTML-Vorschau ist eine read-access-Wurzel wichtig. Die Vorschau sollte nicht nur die einzelne Datei kennen, sondern moeglichst den beobachteten Ordner als Lesebereich.
- Bei `WKWebView` fuer lokale HTML-Vorschau lohnt sich ein expliziter Lade- und Fehlerzustand. Sonst wirkt die Detailansicht bei Problemen schnell wie eine leere, schweigende Flaeche.
- Externe Links sollten die Inline-Vorschau nicht uebernehmen. Fuer diesen Reader passt es besser, externe Ziele im Standardbrowser zu oeffnen und lokale Navigation auf die freigegebene Read-Access-Wurzel zu begrenzen.
- Fuer wiederholbare Preview-Pruefungen sind echte Fixture-HTML-Dateien mit relativen CSS-, Bild- und JavaScript-Assets hilfreicher als nur statische Testdaten ohne Nachbarressourcen.
- In einer headless Terminal-Umgebung ist ein normaler Bildschirm-Screenshot fuer eine macOS-App nicht immer verfuegbar. Offscreen-`WKWebView`-Probetests sind dann ein guter Ersatz, um Asset-Laden realistisch zu pruefen.
- Launch-Overrides fuer Testordner und Startdokument machen UI-nahe Verifikation deutlich leichter, ohne den normalen Produktpfad fuer echte Nutzer zu verbiegen.

## Workflow Gotchas

- Nach jedem abgeschlossenen Schritt muss `docs/current-status.md` aktualisiert werden. Das ist Projektstandard.
- `AGENTS.md` soll nur stabile Regeln und Richtung enthalten, nicht den kompletten Tagesstatus.
- Wenn Tests Fixture-Dateien brauchen, diese sauber als SwiftPM-Test-Resources eintragen statt Warnungen zu ignorieren.
- Bei Parser- oder Scanner-Aenderungen immer auch Gegenbeispiele testen, damit keine zu lockeren Treffer entstehen.
- Bei lokalen Vorschau-Features nicht nur Build und Tests zaehlen lassen. Mindestens ein echter App-Start gehoert in die Verifikation, und spaeter auch eine visuelle Probe mit realen HTML-Dateien.
- Fuer lokale macOS-SwiftPM-Apps lohnt sich frueh ein `script/build_and_run.sh`, das eine echte `.app` baut und startet. Das verhaelt sich naeher an einer normalen Mac-App als `swift run`.
- Wenn ein lokaler Projektordner kein `.git` mehr hat, erst Remote und lokalen Stand vergleichen. Fuer dieses Projekt war der GitHub-Stand nur ein Initial-Commit; der lokale App-Stand musste auf `origin/main` gelegt werden, damit die Remote-History und die MIT-Lizenz erhalten bleiben.

## Infra / Build Notes

- Standard-Verifikation fuer dieses Projekt ist: `swift build`, `swift test` und wenn sinnvoll `swift run DevDashboardFeed`.
- Ein erfolgreicher Build allein reicht nicht. Bei UI-nahen Aenderungen sollte die App mindestens einmal real gestartet werden.
