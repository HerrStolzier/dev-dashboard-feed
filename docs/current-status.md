# Current Status

## Stand vom 2026-04-29

## Zuletzt abgeschlossen

- nativer Folder-Picker mit gespeichertem Ordnerzugriff eingebaut
- gemeinsames Dokument-Modell eingefuehrt
- rekursiver HTML-Scanner eingebaut
- Feed zeigt jetzt echte HTML-Dateien aus beobachteten Ordnern statt nur Sample-Daten
- echte lokale HTML-Vorschau in der Detailansicht eingebaut
- sichtbarer Lade- und Fehlerzustand fuer die lokale HTML-Vorschau eingebaut
- WebView-Navigation enger gefasst: externe Links verlassen die Inline-Vorschau, lokale Pfade ausserhalb der Read-Access-Wurzel werden blockiert
- wiederholbarer Run-Pfad fuer die SwiftPM-macOS-App als `.app` hinzugefuegt
- echte Preview-Fixtures mit CSS, SVG und JavaScript angelegt und ueber WebKit automatisiert geprueft
- Launch-Overrides fuer Testordner und Startdokument eingebaut, damit die Vorschau gezielt mit echten Beispielen hochfahren kann
- lokales Verzeichnis wieder als Git-Repository auf die Remote-History von `HerrStolzier/dev-dashboard-feed` gelegt
- lokaler App-Stand wurde auf `origin/main` gepusht; GitHub ist nicht mehr nur im README-/LICENSE-Startstand
- Remote-`LICENSE` aus dem GitHub-Startstand in den lokalen Arbeitsstand uebernommen
- README mit dem aktuellen lokalen App-Stand abgeglichen

## Was jetzt im Repo wirklich existiert

- SwiftUI-App mit Hauptfenster, Settings und Menu-Bar-Extra
- beobachtete Ordner werden per Bookmark gespeichert und beim Start wiederhergestellt
- HTML-Dateien in beobachteten Ordnern werden rekursiv gefunden
- aus HTML werden aktuell Titel, relativer Pfad, Kurztext, relativer Zeitstempel und ein erster Erklaerbaer-Hinweis extrahiert
- die Detailansicht rendert lokale HTML-Dateien jetzt ueber `WKWebView`
- fuer lokale Vorschau wird eine read-access-Wurzel verwendet, damit relative Assets innerhalb des beobachteten Ordners eher funktionieren
- die Detailansicht zeigt fuer die HTML-Vorschau jetzt einen sichtbaren Ladezustand statt stiller Leere
- klare Fehlermeldungen fuer typische WebView-Fehler sind eingebaut, etwa bei verschwundenen Dateien oder fehlendem Lesezugriff
- externe Links aus der HTML-Vorschau werden im Standardbrowser geoeffnet, statt die lokale Inline-Vorschau zu uebernehmen
- `script/build_and_run.sh` baut jetzt eine lokale `.app`-Bundle-Version und startet sie als echte macOS-App
- `.codex/environments/environment.toml` bindet den lokalen Run-Button an dieses Script
- `.git` ist wieder vorhanden und `origin` zeigt auf `https://github.com/HerrStolzier/dev-dashboard-feed.git`
- `main` trackt `origin/main`
- Launch-Argumente `--watched-folder` und `--selected-document` koennen eine echte Fixture-Vorschau gezielt beim Start oeffnen
- unter `Fixtures/PreviewManual` liegen jetzt echte HTML-Beispiele mit relativen CSS-, SVG- und JavaScript-Assets fuer Vorschau-Checks
- wenn keine beobachteten Ordner vorhanden sind, faellt die App weiter auf Sample-Daten zurueck
- fuer Sample-Daten oder fehlende Dateien zeigt die Detailansicht einen ruhigen Fallback-Zustand

## Wichtige Dateien fuer den aktuellen Stand

- `Sources/DevDashboardFeed/Stores/AppModel.swift`
- `Sources/DevDashboardFeed/Core/Permissions/FolderAccessManager.swift`
- `Sources/DevDashboardFeed/Core/Indexing/DocumentScanner.swift`
- `Sources/DevDashboardFeed/Models/DocumentItem.swift`
- `Sources/DevDashboardFeed/Features/Feed/ContentView.swift`
- `Sources/DevDashboardFeed/Core/Launch/LaunchOverrides.swift`
- `Sources/DevDashboardFeed/Features/Detail/DocumentDetailView.swift`
- `Sources/DevDashboardFeed/Features/Detail/LocalHTMLPreviewSource.swift`
- `Sources/DevDashboardFeed/Features/Detail/LocalHTMLPreviewView.swift`
- `Tests/DevDashboardFeedTests/DevDashboardFeedTests.swift`
- `Tests/DevDashboardFeedTests/LocalHTMLPreviewWebViewTests.swift`
- `Fixtures/PreviewManual/`
- `script/build_and_run.sh`
- `.codex/environments/environment.toml`
- `LICENSE`

## Letzte Verifikation

- `swift build` am 2026-04-29 erfolgreich
- `swift test` am 2026-04-29 erfolgreich, 15 Tests gruen
- `./script/build_and_run.sh --verify --watched-folder <fixture-root> --selected-document <fixture-doc>` am 2026-04-29 erfolgreich; die App startet als `.app`
- GitHub-Remote `origin/main` am 2026-04-29 erfolgreich aktualisiert
- neue Unit-Tests decken jetzt Preview-Navigation innerhalb/ausserhalb der Read-Access-Wurzel sowie klare Fehlertexte fuer Ladefehler ab
- neue WebKit-Probe-Tests laden echte Fixture-HTML-Dateien und bestaetigen dabei erfolgreich lokales CSS, JavaScript und SVG-Assets auch aus einem verschachtelten Unterordner
- ein normaler Desktop-Screenshot war in dieser Terminal-Umgebung nicht verfuegbar, deshalb wurde die Asset-Verifikation ueber offscreen-WebKit statt ueber einen sichtbaren Bildschirmtest abgesichert

## Naechster kleinster sinnvoller Schritt

Den File-Watcher als naechsten groesseren, aber jetzt sinnvoll vorbereiteten Block angehen.

Das sollte moeglichst klein bleiben:

- Dateiaenderungen in beobachteten Ordnern erkennen
- Event-Flut abfedern, damit Generierungslaeufe nicht permanent komplette Rescans anstossen
- den vorhandenen Scanner gezielt und ruhig neu anwerfen
- einen spaeteren echten Desktop-Klicktest fuer Link-Gefuehl und visuelle Feinheiten getrennt offen lassen

## Offene Luecken und Risiken

- es gibt noch keinen File-Watcher fuer automatische Aktualisierung
- ein echter sichtbarer Desktop-Klicktest fuer Link-Gefuehl und Feinschliff steht weiterhin aus
- sehr grosse HTML-Dateien wurden noch nicht auf UI-Ruckler geprueft
- Erklaerbaer-Erkennung ist bewusst einfach und sollte spaeter vorsichtig erweitert werden
- einzelne fehlende Subresources innerhalb einer sonst erfolgreichen HTML-Seite werden noch nicht explizit als eigener UI-Hinweis gesammelt

## Arbeitsregel fuer den naechsten Agent

Wenn du einen Schritt abschliesst, aktualisiere zuerst dieses Dokument.
Wenn du dabei etwas lernst, das auch in drei Sessions noch wichtig ist, trage es zusätzlich in `docs/project-learnings.md` ein.
