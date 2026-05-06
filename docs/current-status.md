# Current Status

## Stand vom 2026-04-29

## Zuletzt abgeschlossen

- Erster echter Background-Agent-MVP umgesetzt:
  - gemeinsamer Digest-Runtime-/Command-Pfad fuer App und CLI
  - CLI-Modus `--run-digests-once`
  - LaunchAgent-Plist mit `StartCalendarInterval` fuer 20:00
  - Install/Uninstall/Kickstart ueber App-Settings und `script/build_and_run.sh`
  - Agent-Programmumgebung explizit auf einen minimalen `PATH` gesetzt
- Weiterentwicklungsplan fuer den echten 20:00-Daily-Digest-Background-Agent erstellt: `daily-digest-background-agent-plan.md`.
- Produkt-Richtung aktualisiert: Devboard ist jetzt ein privater, bunter Projekt-Social-Feed, nicht mehr primaer ein ruhiger Reader.
- TurboQuant-Referenz `/Users/clawdkent/Desktop/projekte-codex/turboquant-mlx-report.html` als Designrichtung uebernommen.
- Project-Repos koennen lokal gespeichert, aktiviert/deaktiviert und entfernt werden.
- Project-Repos speichern jetzt ebenfalls Bookmark-Daten, damit der Zugriff naeher am bestehenden macOS-Ordnerzugriff bleibt.
- Git-Commits werden lokal gelesen und nach Author-Date seit dem letzten Crawl gefiltert; der Scanner begrenzt `git log` vor dem teuren `git show`-Teil.
- Daily-Digest-HTMLs werden im TurboQuant-Stil erzeugt: Dark Background, Gradient-Headline, Badge-Reihe, Explainer-Box, Phase-Karte, Datei-Matrix und Rec-Card.
- Generierte Digests werden zentral unter Application Support abgelegt, nicht im jeweiligen Repo.
- Der Feed zeigt Daily Digests als farbige Social Cards mit Projektakzent und eigener Quellenart.
- Settings haben jetzt einen Bereich fuer `Project Repos` und einen manuellen Button `Run Daily Digests`.
- Der manuelle Digest-Lauf startet die Git-Arbeit im Hintergrund, damit groessere Repos die SwiftUI-Oberflaeche nicht einfrieren.
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
  - `DigestRuntime`
  - `ProjectRepoAccess`
  - `ProjectRepoStore`
  - `GitActivityScanner`
  - `DailyDigestRenderer`
  - `DailyDigestRunner`
  - `DailyDigestCommand`
  - `DigestScheduler`
  - `DigestLaunchAgentPlist`
  - `DigestLaunchAgentInstaller`
  - `DigestBackgroundService`
- `DigestCLI` verzweigt beim Start frueh fuer `--run-digests-once`, `--install-digest-agent`, `--uninstall-digest-agent` und `--kickstart-digest-agent`.
- `script/build_and_run.sh` kann jetzt `digest-once`, `install-agent`, `kickstart-agent` und `uninstall-agent`.
- `ProjectRepoStore` speichert Repo-Konfiguration lokal als JSON.
- Repo-Konfigurationen enthalten optionale Security-Scoped Bookmarks; alte gespeicherte Eintraege ohne Bookmark bleiben weiter lesbar.
- `GitActivityScanner` prueft Git-Worktrees ueber `/usr/bin/git`, ruft Git ohne Shell-String auf und liest Commit-Metadaten plus geaenderte Dateien.
- `DailyDigestRunner` kapselt den schweren Digest-Lauf, damit die UI ihn per `Task.detached` starten kann.
- `DailyDigestRenderer` erzeugt selbststaendige HTML-Dateien mit eingebettetem CSS im TurboQuant-Stil.
- `AppModel.runDailyDigests(now:)` erzeugt pro aktivem Repo und Tag eine HTML-Datei, wenn neue Commits gefunden wurden.
- Settings zeigt jetzt eine `Daily Digest Automation`-Sektion fuer Installieren, Entfernen und einmaliges Starten des lokalen 20:00-LaunchAgents.
- Repo-Ordnernamen fuer Digest-Dateien werden sanitisiert und mit einem kurzen Repo-ID-Suffix kollisionsaermer gemacht.
- Wenn keine Quellen vorhanden sind, faellt die App weiter auf Sample-Daten zurueck.

## Wichtige Dateien fuer den aktuellen Stand

- `daily-digest-background-agent-plan.md`
- `AGENTS.md`
- `Sources/DevDashboardFeed/Stores/AppModel.swift`
- `Sources/DevDashboardFeed/App/DigestCLI.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestRuntime.swift`
- `Sources/DevDashboardFeed/Core/Digests/ProjectRepoAccess.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestCommand.swift`
- `Sources/DevDashboardFeed/Core/Digests/ProjectRepoStore.swift`
- `Sources/DevDashboardFeed/Core/Digests/GitActivityScanner.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestRenderer.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestRunner.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestLaunchAgentPlist.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestLaunchAgentInstaller.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestBackgroundService.swift`
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

- Planungsrunde am 2026-05-06: Code-/Doku-Stand geprueft, Apple-Hinweise zu `SMAppService`/Background Tasks/LaunchAgents beruecksichtigt.
- Umsetzung am 2026-05-06:
  - `swift test` erfolgreich, 25 Tests gruen.
  - `swift build` erfolgreich.
  - `swift run DevDashboardFeed --run-digests-once --quiet` erfolgreich, Exit-Code 0.
  - `script/build_and_run.sh digest-once --quiet` erfolgreich, Exit-Code 0.
  - `script/build_and_run.sh install-agent` erfolgreich; LaunchAgent unter `~/Library/LaunchAgents/com.herrstolzier.DevDashboardFeed.daily-digest.plist` erzeugt.
  - `launchctl print gui/$(id -u)/com.herrstolzier.DevDashboardFeed.daily-digest` bestaetigt ProgramArguments und 20:00-Calendar-Trigger.
  - `script/build_and_run.sh kickstart-agent` erfolgreich; `launchctl` zeigte danach `runs = 1` und `last exit code = 0`.
  - `script/build_and_run.sh uninstall-agent` erfolgreich; Plist wurde wieder entfernt.
  - `script/build_and_run.sh --verify` erfolgreich; die App startet als `.app`.
  - Nach der Verifikation ist der Test-LaunchAgent nicht installiert.
- `swift test` am 2026-04-29 nach Review-Fixes erneut erfolgreich, 19 Tests gruen.
- `swift build` am 2026-04-29 nach Review-Fixes erneut erfolgreich.
- `git diff --check` am 2026-04-29 erfolgreich.
- `script/build_and_run.sh --verify` am 2026-04-29 erfolgreich; die App startet als `.app`.
- Browser-use Visual-QA am 2026-04-29:
  - TurboQuant-Referenz im In-App-Browser bestaetigt: `TurboQuant + MLX auf Apple Silicon`.
  - Generiertes Digest-HTML im In-App-Browser geoeffnet: `timeline Daily Digest`.
  - Sichtbar bestaetigt: dunkler Hintergrund, Gradient-Headline, Badge Row, Explainer-Box, Phase-Karte, Datei-Matrix und Rec-Card.
- Neue Tests decken Repo-Store, Git-Commit-Erkennung seit Cutoff, Renderer-Klassen und AppModel-Digest-Erzeugung ab.

## Naechster kleinster sinnvoller Schritt

Den Agent-MVP in der echten App pruefen: Project Repo in Settings auswaehlen, Agent installieren, einmal kickstarten, generierten Digest im Feed und im Browser visuell pruefen.

Das sollte bewusst in einem kleinen Schritt passieren:

- danach entscheiden, ob der LaunchAgent-MVP reicht oder ob ein eingebetteter Helper mit `SMAppService` wirklich benoetigt wird
- `SMAppService` nur einbauen, wenn die Bundle-Struktur dafuer wirklich passt
- Nachhol-Lauf im App-Start sichtbarer machen, ohne automatisch unbemerkt Git-Scans loszutreten

## Offene Luecken und Risiken

- Der lokale LaunchAgent-MVP ist implementiert und testbar, aber noch kein eingebetteter `SMAppService`-Helper.
- `launchctl print` zeigt im Diagnosekontext auch geerbte Domain-Umgebung; die eigentliche Agent-Plist setzt einen minimalen `PATH`, aber sensible Terminal-Umgebung sollte beim Installieren trotzdem vermieden werden.
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
