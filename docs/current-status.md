# Current Status

## Stand vom 2026-05-15

## Zuletzt abgeschlossen

- Erster echter Background-Agent-MVP umgesetzt:
  - gemeinsamer Digest-Runtime-/Command-Pfad fuer App und CLI
  - CLI-Modus `--run-digests-once`
  - LaunchAgent-Plist mit `StartCalendarInterval` fuer 20:00
  - Install/Uninstall/Kickstart ueber App-Settings und `script/build_and_run.sh`
  - Agent-Programmumgebung explizit auf einen minimalen `PATH` gesetzt
- Naechste Agent-Iteration umgesetzt:
  - persistente Digest-Run-Metadaten fuer letzter Lauf, letzter Erfolg, letzter Fehler und naechster geplanter Lauf
  - Settings zeigt diese Metadaten in der Daily-Digest-Automation-Sektion
  - verpasste 20:00-Laeufe werden konkreter mit Datum/Uhrzeit angezeigt
  - CLI-Testpfade fuer Repo-Store, Digest-Output und Metadata-Store
  - End-to-End-Script `script/verify_daily_digest_agent.sh` gegen ein temporaeres Git-Repo
- App-Flow fuer Agent-Kickstart nachgezogen:
  - AppModel kann Repo-Store, Run-Metadaten und Digest-HTMLs nach einem externen Agent-Lauf neu laden
  - `Run Agent Now` wartet kurz auf frische Agent-Ausgabe und aktualisiert danach Feed und Status
  - Background-Service ist ueber ein kleines Protokoll testbar
  - Regressionstest deckt den Fall ab, dass ein externer Agent Store-Dateien und Digest-HTML schreibt
- Dokumentation geprueft und README aktualisiert:
  - README beschreibt jetzt die aktuelle bunte Devboard-/Daily-Digest-Richtung statt des alten ruhigen Reader-Ziels
  - Dokumentationskarte ergaenzt: README, AGENTS, current-status, project-learnings und aktive Plan-Datei
  - Plan Summary als eigenes README-Kapitel ergaenzt
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
- Ein einfacher `DigestScheduler` erkennt verpasste 20:00-Laeufe als App-Hinweis; der LaunchAgent-MVP kann installiert, entfernt und testweise gestartet werden.
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
  - `DigestRunMetadataStore`
- `DigestCLI` verzweigt beim Start frueh fuer `--run-digests-once`, `--install-digest-agent`, `--uninstall-digest-agent` und `--kickstart-digest-agent`.
- `DigestCLI` kann fuer Tests isolierte Pfade ueber `--project-repo-store`, `--digest-output-root` und `--digest-metadata-store` verwenden.
- `script/build_and_run.sh` kann jetzt `digest-once`, `install-agent`, `kickstart-agent` und `uninstall-agent`.
- `script/verify_daily_digest_agent.sh` baut ein temporaeres Git-Repo, laesst den CLI-Digest laufen und prueft das erzeugte TurboQuant-HTML.
- `ProjectRepoStore` speichert Repo-Konfiguration lokal als JSON.
- Repo-Konfigurationen enthalten optionale Security-Scoped Bookmarks; alte gespeicherte Eintraege ohne Bookmark bleiben weiter lesbar.
- `GitActivityScanner` prueft Git-Worktrees ueber `/usr/bin/git`, ruft Git ohne Shell-String auf und liest Commit-Metadaten plus geaenderte Dateien.
- `DailyDigestRunner` kapselt den schweren Digest-Lauf, damit die UI ihn per `Task.detached` starten kann.
- `DailyDigestRenderer` erzeugt selbststaendige HTML-Dateien mit eingebettetem CSS im TurboQuant-Stil.
- `AppModel.runDailyDigests(now:)` erzeugt pro aktivem Repo und Tag eine HTML-Datei, wenn neue Commits gefunden wurden.
- Settings zeigt jetzt eine `Daily Digest Automation`-Sektion fuer Installieren, Entfernen und einmaliges Starten des lokalen 20:00-LaunchAgents.
- Nach `Run Agent Now` pollt die App kurz die lokalen Stores und aktualisiert Feed, Repo-Status und Run-Metadaten, sobald der externe Agent fertig geschrieben hat.
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
- `Sources/DevDashboardFeed/Core/Digests/DigestRunMetadataStore.swift`
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
- `Sources/DevDashboardFeed/Models/DigestRunMetadata.swift`
- `Sources/DevDashboardFeed/Models/DocumentSourceKind.swift`
- `Sources/DevDashboardFeed/Features/Settings/SettingsView.swift`
- `Sources/DevDashboardFeed/Features/Feed/FeedCardView.swift`
- `Sources/DevDashboardFeed/Features/Detail/DocumentDetailView.swift`
- `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- `Tests/DevDashboardFeedTests/DevDashboardFeedTests.swift`
- `script/verify_daily_digest_agent.sh`
- `README.md`

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
- Weitere Umsetzung am 2026-05-06:
  - `swift test` erfolgreich, 27 Tests gruen.
  - `script/verify_daily_digest_agent.sh` erfolgreich; temporaeres Git-Repo erzeugte ein Digest-HTML mit Commit-Inhalt und TurboQuant-CSS.
  - `swift build` erfolgreich.
  - `script/build_and_run.sh --verify` erfolgreich.
  - `git diff --check` erfolgreich.
  - Nach der Verifikation ist weiterhin kein Test-LaunchAgent installiert.
- Umsetzung am 2026-05-15:
  - `swift test` erfolgreich, 28 Tests gruen.
  - `swift build` erfolgreich.
  - `script/verify_daily_digest_agent.sh` erfolgreich; temporaeres Git-Repo erzeugte ein Digest-HTML.
  - `script/build_and_run.sh --verify` erfolgreich.
  - Browser-use/Playwright-Pruefung ueber lokalen HTTP-Server erfolgreich: generiertes Digest-HTML zeigte Titel, Badge-Zeile, Explainer, Aktivitaetskarte, Dateitabelle und Rec-Card. Einziger Console-Fehler war ein erwartbarer fehlender `/favicon.ico`.
- Dokumentationsrunde am 2026-05-15:
  - Markdown-Dokumente geprueft: `README.md`, `AGENTS.md`, `daily-digest-background-agent-plan.md`, `docs/current-status.md`, `docs/project-learnings.md`.
  - Aktiver Plan bestaetigt: `daily-digest-background-agent-plan.md`.
  - Aelterer breiter Produktplan bestaetigt: `/Users/clawdkent/Desktop/projekte-codex/dev-dashboard-feed-plan.md`.
  - README wurde mit Dokumentationskarte und Plan Summary aktualisiert.
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

Den Agent-MVP mit einem echten eigenen Repo in der laufenden App benutzen: Project Repo in Settings auswaehlen, Agent installieren, einmal kickstarten und pruefen, ob der Feed direkt danach den neuen Digest zeigt.

Das sollte bewusst in einem kleinen Schritt passieren:

- danach entscheiden, ob der LaunchAgent-MVP reicht oder ob ein eingebetteter Helper mit `SMAppService` wirklich benoetigt wird
- `SMAppService` nur einbauen, wenn die Bundle-Struktur dafuer wirklich passt
- danach den File-Watcher fuer beobachtete HTML-Ordner angehen
- README bei groesseren Richtungswechseln mitziehen, damit oeffentliche Uebersicht und interne Handoff-Doku nicht auseinanderlaufen

## Offene Luecken und Risiken

- Der lokale LaunchAgent-MVP ist implementiert und testbar, aber noch kein eingebetteter `SMAppService`-Helper.
- Persistente Run-Metadaten existieren, aber es gibt noch keine detaillierte Run-Historie pro Repo.
- `launchctl print` zeigt im Diagnosekontext auch geerbte Domain-Umgebung; die eigentliche Agent-Plist setzt einen minimalen `PATH`, aber sensible Terminal-Umgebung sollte beim Installieren trotzdem vermieden werden.
- Browser-use/Playwright-QA fuer die neue Agent-E2E-Datei wurde ueber lokalen HTTP-Server ausgefuehrt; direkte `file://`-Navigation war im Browser-Tool blockiert.
- File-Watcher fuer automatische Aktualisierung beobachteter HTML-Ordner fehlt weiterhin.
- Sehr grosse Git-Historien koennen beim ersten Tageslauf noch teuer werden, auch wenn der Default-Cutoff jetzt Tagesanfang ist.
- Mehrere Repos mit gleichem Namen sind durch ID-Suffixe im Digest-Pfad besser getrennt, aber die UI zeigt noch keine explizite Kollisionshilfe.
- Sehr grosse HTML-Dateien wurden noch nicht auf UI-Ruckler geprueft.
- Erklaerbaer-Erkennung ist bewusst einfach und sollte spaeter vorsichtig erweitert werden.
- Einzelne fehlende Subresources innerhalb einer sonst erfolgreichen HTML-Seite werden noch nicht explizit als eigener UI-Hinweis gesammelt.
- Der aeltere breite Produktplan neben dem Repo beschreibt noch das urspruengliche ruhigere HTML-Reader-Ziel; README und AGENTS sind jetzt aktueller fuer die bunte Devboard-Richtung.

## Arbeitsregel fuer den naechsten Agent

Beginne mit diesem Dokument.
Wenn du einen Schritt abschliesst, aktualisiere zuerst dieses Dokument.
Wenn du dabei etwas lernst, das auch in drei Sessions noch wichtig ist, trage es zusaetzlich in `docs/project-learnings.md` ein.
