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
- Die Produkt-Richtung ist jetzt ausdruecklich bunt, persoenlich und projektzentriert. "Ruhig" ist nicht mehr das Zielbild; TurboQuant-Style ist die visuelle Referenz.
- Daily-Digest-HTMLs sollen selbststaendig sein: eingebettetes CSS, keine externen Assets als harte Voraussetzung, WebView-kompatibel.
- Generierte Projektposts gehoeren in Application Support, nicht in die beobachteten HTML-Ordner und nicht in die Git-Repos selbst.
- Git-Commits sind die Digest-Quelle. Uncommitted Working-Tree-Dateien sollen nicht als Aktivitaet in Daily Digests eingehen.
- Git sollte ueber `Process` mit Argument-Array aufgerufen werden, nicht ueber zusammengesetzte Shell-Strings. Das haelt Repo-Pfade und Commit-Inhalte deutlich einfacher kontrollierbar.
- Commit-Inhalte, Dateipfade und Repo-Namen muessen im Digest-HTML escaped werden. Der Renderer darf nie Rohwerte direkt als HTML einsetzen.
- Fuer Tests mit historischen Commit-Zeitpunkten ist Author-Date wichtig. `git log --since` kann wegen Committer-Date unerwartet sein; deshalb filtert der Scanner die geparsten Author-Dates in Swift.
- Fuer groessere Repos muss der teure Teil des Git-Scans begrenzt bleiben. Erst `git log --since`, dann Author-Date nachfiltern, und `git show` nur noch fuer die uebrig gebliebenen Commits ausfuehren.
- Manuelle Digest-Laeufe duerfen nicht synchron auf dem Main Actor laufen. Git-Prozesse und HTML-Dateischreiben gehoeren in einen Hintergrundlauf; die UI aktualisiert danach nur den Status und den Feed.
- Project-Repos sollten wie watched folders Bookmark-Daten speichern. Nackte Pfade reichen fuer einen lokalen Dev-Flow, aber nicht fuer robuste Restart-/Helper-Szenarien.
- Ein echter 20:00-Background-Agent sollte nicht vorgetaeuscht werden. Erst die Bundle-/Helper-Struktur klaeren, dann `SMAppService` oder LaunchAgent-Plist sauber anschliessen.
- Fuer den privaten MVP ist ein LaunchAgent plus `--run-digests-once` der stabilere erste Automatikpfad als sofort ein eingebetteter `SMAppService`-Helper.
- Agent-Kommandos muessen ohne `open` laufen, damit stdout/stderr und Exit-Code pruefbar bleiben.
- LaunchAgent-Plists sollten `ProgramArguments` mit absoluten Pfaden und eine minimale `EnvironmentVariables`-Umgebung setzen. Beim Installieren aus einem Terminal kann `launchctl print` trotzdem geerbte Domain-Umgebung anzeigen; sensible Terminal-Umgebung beim Bootstrap vermeiden.
- Agent-Tests sollten immer Install, `launchctl print`, Kickstart und Uninstall enthalten. Sonst prueft man nur die Plist-Datei, nicht den echten launchd-Pfad.
- Persistente Digest-Run-Metadaten sind fuer Background-Agenten wichtig. Ohne letzten Lauf, letzten Erfolg, naechsten Planlauf und letzten Fehler ist die Automatik fuer den Nutzer praktisch unsichtbar.
- CLI-Pfad-Overrides fuer Repo-Store, Digest-Output und Metadata-Store machen Agent-Integrationstests sicherer, weil echte lokale App-Daten nicht beruehrt werden.
- Ein temporaeres Git-Repo als End-to-End-Test ist der beste kleine Realitaetscheck fuer den Digest-Agenten: Git, Store, Renderer und Metadata-Update laufen dabei gemeinsam durch.
- Browser-use Visual-QA ist fuer HTML-Renderer wertvoll, aber nicht gleichwertig mit Content-Pruefungen. Wenn der Browser-Use Node-RePL nicht verfuegbar ist, sollten wenigstens HTML-Inhalt, CSS-Signaturen und erzeugte Artefaktpfade automatisch geprueft werden.
- Wenn ein LaunchAgent ausserhalb des laufenden AppModels schreibt, muss die App danach Repo-Store, Run-Metadaten und Digest-Ordner neu laden. Sonst ist der Agent technisch erfolgreich, aber die UI wirkt alt.
- Beim erneuten Wiederherstellen von Project-Repo-Bookmarks alte Security-Scoped-Zugriffe sauber stoppen, bevor neue aktive URLs uebernommen werden.
- Wenn Browser-Tools lokale `file://`-URLs blockieren, ist ein kurzer lokaler HTTP-Server ein brauchbarer visueller QA-Pfad fuer selbststaendige Digest-HTMLs.
- README, AGENTS und current-status koennen bei schnellen Produktwechseln auseinanderlaufen. Bei Richtungswechseln immer mindestens README und current-status zusammen pruefen.
- Pixelpunk soll als Interface-Sprache funktionieren, nicht als reine Deko. Gute Anwendung: Quest-/Artifact-Karten, LVL/XP-Badges, dunkle Panels, neonartige Akzente. Schlechte Anwendung: alles schwer lesbar verpixeln.
- Pixelpunk wird unstimmig, wenn native Systemauswahl, viele verschiedene Corner-Radii, vollfarbige Sektion-Outlines und riesige Panelbreiten gleichzeitig auftreten. Erst ein gemeinsames Panel- und Auswahlmodell stabilisieren, dann Details verspielter machen.
- Das Mockup-Ziel ist staerker als "Pixel-Akzente": Es ist ein eigenes kleines Pixel-OS. App-Rahmen, Sidebar, Topbar, Cards und Detailmodule muessen aus einem System kommen, sonst wirkt es sofort zusammengesteckt.

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
- Bei Design-aehnlichen HTML-Renderern lohnt sich Browser-use gegen eine echte `file://`-Datei. Tests pruefen Klassen und Text, aber der Browser zeigt, ob Gradient, Badges und Karten wirklich als Seite wirken.
