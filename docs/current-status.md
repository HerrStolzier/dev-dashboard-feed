# Current Status

## Stand vom 2026-04-29

## Zuletzt abgeschlossen

- Produkt-Richtung aktualisiert: Devboard ist jetzt ein privater, bunter Projekt-Social-Feed, nicht mehr primaer ein ruhiger Reader.
- TurboQuant-Referenz `/Users/clawdkent/Desktop/projekte-codex/turboquant-mlx-report.html` als Designrichtung uebernommen.
- Project-Repos koennen lokal gespeichert, aktiviert/deaktiviert und entfernt werden.
- Git-Commits werden lokal gelesen und nach Author-Date seit dem letzten Crawl gefiltert.
- Daily-Digest-HTMLs werden im TurboQuant-Stil erzeugt: Dark Background, Gradient-Headline, Badge-Reihe, Explainer-Box, Phase-Karte, Datei-Matrix und Rec-Card.
- Generierte Digests werden zentral unter Application Support abgelegt, nicht im jeweiligen Repo.
- Der Feed zeigt Daily Digests als farbige Social Cards mit Projektakzent und eigener Quellenart.
- Settings haben jetzt einen Bereich fuer `Project Repos` und einen manuellen Button `Run Daily Digests`.
- Ein einfacher `DigestScheduler` erkennt verpasste 20:00-Laeufe als App-Hinweis; der echte LaunchAgent ist noch nicht paketiert.
- `AGENTS.md` wurde auf die neue bunte Devboard-Richtung aktualisiert.

## Was jetzt im Repo wirklich existiert

- SwiftUI-App mit Hauptfenster, Settings und Menu-Bar-Extra.
- Beobachtete HTML-Ordner werden per Bookmark gespeichert und beim Start wiederhergestellt.
- HTML-Dateien in beobachteten Ordnern werden rekursiv gefunden.
- Die Detailansicht rendert lokale HTML-Dateien ueber `WKWebView`.
- `DocumentItem` kennt jetzt `sourceKind`, `accentColor`, `generatedAt` und `modifiedAt`.
- `DocumentScanner` kann normale HTML-Artefakte und generierte Daily Digests getrennt markieren.
- Neue Modelle:
  - `ProjectRepo`
  - `GitCommitActivity`
  - `GitRepoActivity`
  - `DigestRunResult`
  - `DocumentSourceKind`
- Neue Digest-/Repo-Services:
  - `ProjectRepoStore`
  - `GitActivityScanner`
  - `DailyDigestRenderer`
  - `DigestScheduler`
- `ProjectRepoStore` speichert Repo-Konfiguration lokal als JSON.
- `GitActivityScanner` prueft Git-Worktrees ueber `/usr/bin/git`, ruft Git ohne Shell-String auf und liest Commit-Metadaten plus geaenderte Dateien.
- `DailyDigestRenderer` erzeugt selbststaendige HTML-Dateien mit eingebettetem CSS im TurboQuant-Stil.
- `AppModel.runDailyDigests(now:)` erzeugt pro aktivem Repo und Tag eine HTML-Datei, wenn neue Commits gefunden wurden.
- Repo-Ordnernamen fuer Digest-Dateien werden sanitisiert und mit einem kurzen Repo-ID-Suffix kollisionsaermer gemacht.
- Wenn keine Quellen vorhanden sind, faellt die App weiter auf Sample-Daten zurueck.

## Wichtige Dateien fuer den aktuellen Stand

- `AGENTS.md`
- `Sources/DevDashboardFeed/Stores/AppModel.swift`
- `Sources/DevDashboardFeed/Core/Digests/ProjectRepoStore.swift`
- `Sources/DevDashboardFeed/Core/Digests/GitActivityScanner.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestRenderer.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestScheduler.swift`
- `Sources/DevDashboardFeed/Core/Indexing/DocumentScanner.swift`
- `Sources/DevDashboardFeed/Models/DocumentItem.swift`
- `Sources/DevDashboardFeed/Models/ProjectRepo.swift`
- `Sources/DevDashboardFeed/Models/DailyDigest.swift`
- `Sources/DevDashboardFeed/Models/DocumentSourceKind.swift`
- `Sources/DevDashboardFeed/Features/Settings/SettingsView.swift`
- `Sources/DevDashboardFeed/Features/Feed/FeedCardView.swift`
- `Sources/DevDashboardFeed/Features/Detail/DocumentDetailView.swift`
- `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- `Tests/DevDashboardFeedTests/DevDashboardFeedTests.swift`

## Letzte Verifikation

- `swift test` am 2026-04-29 erfolgreich, 19 Tests gruen.
- `swift build` am 2026-04-29 erfolgreich.
- `git diff --check` am 2026-04-29 erfolgreich.
- `script/build_and_run.sh --verify` am 2026-04-29 erfolgreich; die App startet als `.app`.
- Browser-use Visual-QA am 2026-04-29:
  - TurboQuant-Referenz im In-App-Browser bestaetigt: `TurboQuant + MLX auf Apple Silicon`.
  - Generiertes Digest-HTML im In-App-Browser geoeffnet: `timeline Daily Digest`.
  - Sichtbar bestaetigt: dunkler Hintergrund, Gradient-Headline, Badge Row, Explainer-Box, Phase-Karte, Datei-Matrix und Rec-Card.
- Neue Tests decken Repo-Store, Git-Commit-Erkennung seit Cutoff, Renderer-Klassen und AppModel-Digest-Erzeugung ab.

## Naechster kleinster sinnvoller Schritt

Den echten Background-Agent fuer den 20:00-Lauf bauen.

Das sollte bewusst in einem kleinen Schritt passieren:

- entscheiden, ob die aktuelle SwiftPM-App-Bundle-Struktur einen eingebetteten Helper tragen soll oder ob zunaechst ein LaunchAgent-Plist plus CLI-Modus sinnvoller ist
- `SMAppService` nur einbauen, wenn die Bundle-Struktur dafuer wirklich passt
- `StartCalendarInterval` fuer 20:00 sauber abbilden
- Nachhol-Lauf im App-Start sichtbar anbieten, ohne automatisch unbemerkt Git-Scans loszutreten

## Offene Luecken und Risiken

- Der echte LaunchAgent/Helper fuer den taeglichen 20:00-Lauf ist noch nicht implementiert.
- File-Watcher fuer automatische Aktualisierung beobachteter HTML-Ordner fehlt weiterhin.
- Sehr grosse Git-Historien koennen beim ersten Tageslauf noch teuer werden, auch wenn der Default-Cutoff jetzt Tagesanfang ist.
- Mehrere Repos mit gleichem Namen sind durch ID-Suffixe im Digest-Pfad besser getrennt, aber die UI zeigt noch keine explizite Kollisionshilfe.
- Sehr grosse HTML-Dateien wurden noch nicht auf UI-Ruckler geprueft.
- Erklaerbaer-Erkennung ist bewusst einfach und sollte spaeter vorsichtig erweitert werden.
- Einzelne fehlende Subresources innerhalb einer sonst erfolgreichen HTML-Seite werden noch nicht explizit als eigener UI-Hinweis gesammelt.

## Arbeitsregel fuer den naechsten Agent

Beginne mit diesem Dokument.
Wenn du einen Schritt abschliesst, aktualisiere zuerst dieses Dokument.
Wenn du dabei etwas lernst, das auch in drei Sessions noch wichtig ist, trage es zusaetzlich in `docs/project-learnings.md` ein.
