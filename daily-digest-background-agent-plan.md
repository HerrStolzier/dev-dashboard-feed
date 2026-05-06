# Plan: Daily Digest Background Agent

**Generated**: 2026-05-06  
**Estimated Complexity**: High

## Overview

Devboard kann Daily Digests bereits manuell erzeugen. Der naechste Schritt ist ein echter lokaler 20:00-Lauf, der dieselbe Digest-Logik verwendet, ohne die SwiftUI-App offen halten zu muessen.

Der Plan baut das in kleinen, testbaren Schichten:

1. Digest-Kern so freistellen, dass App und Helper/CLI denselben Code nutzen.
2. Einen einmaligen CLI/Helper-Lauf einbauen: `--run-digests-once`.
3. Eine LaunchAgent-Beschreibung fuer 20:00 erstellen und lokal pruefbar machen.
4. Wenn die Bundle-Struktur passt, `SMAppService` als Registrierungsweg anbinden.
5. Settings um Automatik-Status, Nachholen und Fehleranzeige erweitern.

Wichtig: Keine Schein-Automatik. Wenn `SMAppService` mit der aktuellen SwiftPM-`.app`-Struktur nicht sauber genug ist, wird zuerst ein expliziter LaunchAgent/CLI-Pfad gebaut und dokumentiert.

## Prerequisites

- macOS 15+ Zielplattform laut `Package.swift`.
- Bestehender Digest-Kern:
  - `Sources/DevDashboardFeed/Core/Digests/DailyDigestRunner.swift`
  - `Sources/DevDashboardFeed/Core/Digests/GitActivityScanner.swift`
  - `Sources/DevDashboardFeed/Core/Digests/ProjectRepoStore.swift`
  - `Sources/DevDashboardFeed/Core/Digests/DigestScheduler.swift`
  - `Sources/DevDashboardFeed/Stores/AppModel.swift`
- Aktueller App-Bundle-Build:
  - `script/build_and_run.sh`
- Apple-Doku-Hinweise:
  - `SMAppService` ist fuer Login Items, LaunchAgents und LaunchDaemons als Helper im App-Bundle gedacht.
  - `SMAppService.register()` bootstrapped einen LaunchAgent sofort, wenn der Service ein LaunchAgent ist.
  - Apple beschreibt Background Tasks als user-visible System-Settings-/Login-Items-Thema; Testen sollte also auch System Settings/Logs beruecksichtigen.
  - `StartCalendarInterval` ist der passende launchd-Schluessel fuer eine feste Uhrzeit wie 20:00.

## Assumptions

- Ziel ist vorerst dein privater lokaler Workflow, nicht App-Store-/Team-signiertes Deployment.
- Keine Cloud, keine API, keine AI-Zusammenfassung.
- Daily Digests verwenden nur Git-Commits, keine uncommitted Working-Tree-Dateien.
- Der automatische Lauf darf sichtbar Status hinterlassen, soll aber keine UI erzwingen.
- Der erste robuste Weg darf ein LaunchAgent/CLI-Modus sein, auch wenn `SMAppService` danach eleganter angebunden wird.

## Sprint 1: Digest Runtime Entkoppeln

**Goal**: Der Digest-Lauf ist ausserhalb von `AppModel` sauber wiederverwendbar und kann von App, Tests und spaeter Helper/CLI identisch gestartet werden.

**Demo/Validation**:

- `swift test`
- `swift build`
- Ein Test kann den Digest-Lauf ohne SwiftUI/AppModel direkt ausfuehren.

### Task 1.1: Runtime-Konfiguration einfuehren

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DigestRuntime.swift`
  - `Sources/DevDashboardFeed/Core/Digests/ProjectRepoStore.swift`
  - `Sources/DevDashboardFeed/Core/Digests/DailyDigestRunner.swift`
- **Description**: Eine kleine Struktur bauen, die Store-URL, Digest-Output-Root, Scanner, Renderer und FileManager kapselt.
- **Dependencies**: Keine.
- **Acceptance Criteria**:
  - App und CLI muessen dieselben Default-Pfade nutzen.
  - Tests koennen Temp-Pfade injizieren.
  - Keine neue globale mutable State-Quelle.
- **Validation**:
  - Unit-Test fuer Default-Pfade und injizierte Temp-Pfade.

### Task 1.2: Repo-Bookmark-Restore aus `AppModel` herausziehen

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/ProjectRepoAccess.swift`
  - `Sources/DevDashboardFeed/Stores/AppModel.swift`
- **Description**: Die aktuelle Bookmark-Logik fuer Project-Repos aus `AppModel` in einen kleinen Service verschieben.
- **Dependencies**: Task 1.1.
- **Acceptance Criteria**:
  - `AppModel` verliert die privaten statischen Bookmark-Helfer.
  - CLI/Helper kann Repos genauso wiederherstellen wie die App.
  - Alte Repo-Eintraege ohne Bookmark bleiben lesbar, aber werden als potenziell eingeschraenkt behandelt.
- **Validation**:
  - Unit-Test: Repo mit fehlendem/ungueltigem Bookmark wird inaktiv oder liefert klaren Fehler.
  - Bestehende Tests bleiben gruen.

### Task 1.3: `DailyDigestCommand` als synchronen Einmal-Lauf bauen

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DailyDigestCommand.swift`
  - `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- **Description**: Einen nicht-UI Command bauen: Repos laden, Zugriff wiederherstellen, Runner starten, Store aktualisieren, Ergebnis zusammenfassen.
- **Dependencies**: Task 1.1, Task 1.2.
- **Acceptance Criteria**:
  - Rueckgabe enthaelt erzeugt/uebersprungen/fehlgeschlagen.
  - Store wird nur nach abgeschlossenem Lauf geschrieben.
  - Fehler pro Repo blockieren andere Repos nicht.
- **Validation**:
  - Test mit Fake-Scanner: ein Repo erzeugt Digest, ein Repo failed, Store enthaelt aktualisierten Crawl-Zeitpunkt nur fuer erfolgreiche/uebersprungene Repos.

## Sprint 2: CLI/Helper Entry Point

**Goal**: Die gebaute App kann einmalig einen Daily-Digest-Lauf ausfuehren, ohne das normale UI zu starten.

**Demo/Validation**:

- `swift run DevDashboardFeed --run-digests-once`
- `script/build_and_run.sh --verify -- --run-digests-once`
- Exit-Code ist maschinenlesbar.

### Task 2.1: Launch-Argumente erweitern

- **Location**:
  - `Sources/DevDashboardFeed/Core/Launch/LaunchOverrides.swift`
  - `Tests/DevDashboardFeedTests/DevDashboardFeedTests.swift`
- **Description**: Argumente fuer `--run-digests-once`, optional `--digest-now <iso-date>` und `--quiet` parsen.
- **Dependencies**: Sprint 1.
- **Acceptance Criteria**:
  - Normaler App-Start bleibt unveraendert.
  - Testdatum ist nur fuer Tests/Debug nutzbar.
  - Ungueltige ISO-Daten erzeugen klare Fehlermeldung.
- **Validation**:
  - Unit-Tests fuer Argumentparser.

### Task 2.2: App-Entry frueh verzweigen

- **Location**:
  - `Sources/DevDashboardFeed/App/DevDashboardFeedApp.swift`
  - optional: `Sources/DevDashboardFeed/App/DigestCLI.swift`
- **Description**: Beim Start mit `--run-digests-once` den Command ausfuehren und danach ohne SwiftUI-Fenster beenden.
- **Dependencies**: Task 2.1.
- **Acceptance Criteria**:
  - Kein Hauptfenster bei CLI-Modus.
  - stdout/stderr enthalten knappe Ergebniszeilen.
  - Exit-Code `0` bei vollstaendigem Erfolg oder nur skipped, `1` bei mindestens einem failed Repo, `2` bei Konfigurations-/Argumentfehler.
- **Validation**:
  - `swift run DevDashboardFeed --run-digests-once --quiet`
  - Test oder Script-Probe mit temporaerem Store.

### Task 2.3: Build-Script CLI-faehig machen

- **Location**:
  - `script/build_and_run.sh`
- **Description**: Einen Modus `--run-digests-once` oder `digest-once` hinzufuegen, der die gebaute `.app` mit CLI-Argument startet und Exit-Code weitergibt.
- **Dependencies**: Task 2.2.
- **Acceptance Criteria**:
  - Bestehende Modi `run`, `--verify`, `--logs` bleiben kompatibel.
  - CLI-Modus laeuft ohne `open`, damit Exit-Code und Ausgabe erhalten bleiben.
- **Validation**:
  - `script/build_and_run.sh digest-once --quiet`

## Sprint 3: LaunchAgent Plist und Scheduling

**Goal**: Ein lokaler LaunchAgent kann den CLI-Modus um 20:00 starten.

**Demo/Validation**:

- Plist wird erzeugt und syntaktisch geprueft.
- Test-Plist kann in einer kurzfristigen Testvariante gestartet werden.
- Logdatei zeigt Ergebnis des Digest-Laufs.

### Task 3.1: LaunchAgent-Plist-Renderer bauen

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DigestLaunchAgentPlist.swift`
  - `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- **Description**: Renderer fuer eine LaunchAgent-Plist mit `Label`, `ProgramArguments`, `StartCalendarInterval`, `StandardOutPath`, `StandardErrorPath`.
- **Dependencies**: Sprint 2.
- **Acceptance Criteria**:
  - `StartCalendarInterval` enthaelt `Hour = 20`, `Minute = 0`.
  - `ProgramArguments` zeigt auf die gebaute App-Binary oder spaeter Helper-Binary plus `--run-digests-once --quiet`.
  - Pfade liegen unter Application Support/Logs oder vergleichbar lokal.
- **Validation**:
  - Unit-Test parst die erzeugte Plist mit `PropertyListSerialization`.

### Task 3.2: LaunchAgent Installer fuer Dev-Modus

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DigestLaunchAgentInstaller.swift`
  - `script/build_and_run.sh`
- **Description**: Install/Uninstall-Funktionen fuer `~/Library/LaunchAgents/com.herrstolzier.DevDashboardFeed.daily-digest.plist` bauen.
- **Dependencies**: Task 3.1.
- **Acceptance Criteria**:
  - Install schreibt atomar.
  - Uninstall entfernt nur die eigene Plist.
  - Keine fremden LaunchAgents werden angefasst.
  - Pfade mit Leerzeichen funktionieren.
- **Validation**:
  - Unit-Test fuer Pfadberechnung.
  - Manuelle Probe mit temporaerem Output-Verzeichnis, nicht sofort echter 20:00-Lauf.

### Task 3.3: `launchctl`-Probe dokumentiert ausfuehren

- **Location**:
  - `script/build_and_run.sh`
  - `docs/current-status.md`
- **Description**: Dev-Script-Modus fuer `launchctl bootstrap/gui/<uid>`, `kickstart`, `bootout` ergaenzen oder genaue manuelle Schritte dokumentieren.
- **Dependencies**: Task 3.2.
- **Acceptance Criteria**:
  - Testmodus kann sofort gekickstartet werden.
  - Fehler werden sichtbar geloggt.
  - Dokumentiert ist, wie man den Agent wieder entfernt.
- **Validation**:
  - `launchctl print gui/$(id -u)/com.herrstolzier.DevDashboardFeed.daily-digest`
  - Logdatei enthaelt Digest-Ergebnis.

## Sprint 4: SMAppService Integration

**Goal**: Die App bekommt eine native Registrierungsflaeche fuer den Background-Agent, falls die Bundle-Struktur sauber genug ist.

**Demo/Validation**:

- Settings zeigt Status: nicht installiert, installiert, braucht Zustimmung, Fehler.
- Registrierung kann aktiviert/deaktiviert werden.
- System Settings/Login Items zeigt den Background Task nachvollziehbar.

### Task 4.1: Bundle-Struktur pruefen und entscheiden

- **Location**:
  - `script/build_and_run.sh`
  - `dist/DevDashboardFeed.app/Contents/`
  - `docs/current-status.md`
- **Description**: Entscheiden, ob ein separater Helper im App-Bundle gebaut wird oder ob der Hauptbinary-CLI-Modus zunaechst per LaunchAgent genutzt wird.
- **Dependencies**: Sprint 3.
- **Acceptance Criteria**:
  - Entscheidung ist dokumentiert.
  - Wenn Helper: Bundle-Pfad und Info.plist-Struktur sind benannt.
  - Wenn kein Helper: SMAppService bleibt Folgearbeit und LaunchAgent ist offizieller MVP-Weg.
- **Validation**:
  - App-Bundle nach Build inspizieren.
  - `swift build` und `script/build_and_run.sh --verify`.

### Task 4.2: `DigestBackgroundService` einbauen

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DigestBackgroundService.swift`
  - `Sources/DevDashboardFeed/Features/Settings/SettingsView.swift`
- **Description**: Abstraktion fuer Status, Register, Unregister. Intern entweder `SMAppService.agent(plistName:)` oder Dev-LaunchAgent-Installer verwenden.
- **Dependencies**: Task 4.1.
- **Acceptance Criteria**:
  - UI kennt nicht direkt `SMAppService`.
  - Service liefert klare Statuswerte.
  - Fehler enthalten user-lesbare Erklaerung.
- **Validation**:
  - Unit-Tests mit Fake-Service.
  - Manuelle Registrierung/Entfernung im Dev-Modus.

### Task 4.3: Permissions und User-Transparenz pruefen

- **Location**:
  - `docs/current-status.md`
  - optional `README.md`
- **Description**: Verhalten in System Settings, Log-Ausgabe und erlaubte Background-Task-Zustaende dokumentieren.
- **Dependencies**: Task 4.2.
- **Acceptance Criteria**:
  - Dokumentiert ist, wo Nutzer den Task sehen/abschalten koennen.
  - Dokumentiert ist, welche Daten lokal gelesen werden.
  - Kein Hinweis auf Cloud/API.
- **Validation**:
  - Manuelle Sichtpruefung in System Settings.
  - `sfltool dumpbtm` optional als Diagnosehinweis, nicht als Pflicht im normalen Flow.

## Sprint 5: App-UX fuer Automatik und Nachholen

**Goal**: Die Automatik fuehlt sich kontrollierbar an: klarer Status, letzter Lauf, naechster Lauf, Nachholen.

**Demo/Validation**:

- Settings zeigt Automatik-Status und letzten/naechsten Lauf.
- Button „Jetzt nachholen“ startet denselben Hintergrundlauf wie bisher.
- Feed aktualisiert sich nach erfolgreichem Lauf.

### Task 5.1: Persistente Digest-Run-Metadaten

- **Location**:
  - `Sources/DevDashboardFeed/Models/DigestRunMetadata.swift`
  - `Sources/DevDashboardFeed/Core/Digests/DigestRunMetadataStore.swift`
- **Description**: Speichern: letzter Lauf, letzter Erfolg, letzte Fehlermeldung, naechster geplanter Lauf.
- **Dependencies**: Sprint 2.
- **Acceptance Criteria**:
  - Metadata-Store ist testbar mit Temp-URL.
  - Keine Repo-Geheimnisse in Fehlermeldungen uebermaessig breit loggen.
- **Validation**:
  - Unit-Test fuer Speichern/Laden.

### Task 5.2: Settings UI erweitern

- **Location**:
  - `Sources/DevDashboardFeed/Features/Settings/SettingsView.swift`
  - `Sources/DevDashboardFeed/Stores/AppModel.swift`
- **Description**: Toggle/Buttons fuer Automatik, Statuszeilen fuer letzter Lauf/naechster Lauf/Fehler.
- **Dependencies**: Sprint 4, Task 5.1.
- **Acceptance Criteria**:
  - Automatik kann aktiviert/deaktiviert werden.
  - „Jetzt nachholen“ ist deaktiviert, waehrend ein Lauf aktiv ist.
  - Fehler erscheinen knapp und verstaendlich.
- **Validation**:
  - SwiftUI Build.
  - Manuelle App-Probe via `script/build_and_run.sh --verify`.

### Task 5.3: Missed-run Catch-up konkretisieren

- **Location**:
  - `Sources/DevDashboardFeed/Core/Digests/DigestScheduler.swift`
  - `Sources/DevDashboardFeed/Stores/AppModel.swift`
  - `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- **Description**: Verpassten 20:00-Lauf sauber erkennen und als Nachhol-Aktion anbieten.
- **Dependencies**: Task 5.1.
- **Acceptance Criteria**:
  - Kein automatischer unbemerkter Git-Scan beim App-Start.
  - Status sagt konkret, welcher Lauf verpasst wurde.
  - Nutzer kann manuell nachholen.
- **Validation**:
  - Unit-Tests fuer Zeitfaelle: vor 20:00, nach 20:00, naechster Tag, letzter Lauf vorhanden.

## Sprint 6: End-to-End Verifikation und Handoff

**Goal**: Der Background-Agent ist installierbar, testbar, entfernbar und dokumentiert.

**Demo/Validation**:

- Ein Testrepo erzeugt Commit.
- CLI-Lauf erzeugt Digest.
- LaunchAgent/SMAppService-Lauf erzeugt Digest.
- App zeigt Digest im Feed.

### Task 6.1: Integrationstest-Script fuer Temp-Git-Repo

- **Location**:
  - `script/verify_daily_digest_agent.sh`
- **Description**: Temp-Repo erstellen, Commit schreiben, Store auf Temp-Pfad oder Testmodus richten, CLI/Agent-Lauf ausfuehren, HTML-Ausgabe pruefen.
- **Dependencies**: Sprint 3 oder 4.
- **Acceptance Criteria**:
  - Script raeumt eigene LaunchAgent-Testartefakte wieder auf.
  - Test kann ohne echte private Repos laufen.
- **Validation**:
  - `script/verify_daily_digest_agent.sh`

### Task 6.2: Browser-use Visual-QA fuer Agent-erzeugten Digest

- **Location**:
  - generierte Digest-HTML-Datei unter Application Support oder Test-Output
- **Description**: Mit browser-use die vom Agent erzeugte HTML-Datei oeffnen und TurboQuant-Elemente sichtbar pruefen.
- **Dependencies**: Task 6.1.
- **Acceptance Criteria**:
  - Dark Background, Gradient-H1, Badge Row, Explainer, Phase Card, Matrix sichtbar.
  - Console-Logs enthalten keine kritischen Fehler.
- **Validation**:
  - In-App-Browser Screenshot/Sichtprobe.

### Task 6.3: Projekt-Dokumente aktualisieren

- **Location**:
  - `docs/current-status.md`
  - `docs/project-learnings.md`
  - optional `README.md`
- **Description**: Neuen Stand, Verifikation, Risiken und naechsten Schritt dokumentieren.
- **Dependencies**: Alle vorherigen Tasks.
- **Acceptance Criteria**:
  - Naechster Agent kann ohne Chatverlauf starten.
  - Offene Risiken sind ehrlich benannt.
- **Validation**:
  - Dokumente lesen und gegen Implementierung abgleichen.

## Testing Strategy

- **Unit Tests**
  - Argumentparser fuer CLI-Modus.
  - Runtime-Konfiguration und Pfade.
  - ProjectRepo bookmark restore und Fehlerfaelle.
  - LaunchAgent-Plist als Property List parsen.
  - Scheduler-Zeitfaelle.
  - Metadata-Store speichern/laden.

- **Integration Tests**
  - Temp-Git-Repo mit Commit.
  - `DailyDigestCommand` erzeugt HTML und aktualisiert Store.
  - CLI-Modus beendet mit korrektem Exit-Code.
  - LaunchAgent-Testmodus kann per `launchctl kickstart` laufen und Log schreiben.

- **Manual Verification**
  - `swift test`
  - `swift build`
  - `script/build_and_run.sh --verify`
  - CLI: `swift run DevDashboardFeed --run-digests-once --quiet`
  - Agent: `launchctl print`, `kickstart`, `bootout`
  - browser-use fuer erzeugtes Digest-HTML.

## Potential Risks & Gotchas

- **SMAppService braucht passende Bundle-Struktur**  
  Mit der aktuellen SwiftPM-gebauten `.app` kann ein vollwertiger eingebetteter Helper mehr Packaging-Arbeit brauchen. Mitigation: Erst CLI/LaunchAgent als testbaren MVP bauen, dann SMAppService sauber anbinden.

- **Security-scoped bookmarks im Helper**  
  Helper/Agent muss Repo-Bookmarks genauso wiederherstellen wie die App. Mitigation: Bookmark-Restore in gemeinsamen Service ziehen.

- **LaunchAgent sieht andere Umgebung als Terminal**  
  `PATH`, Working Directory und Shell-Umgebung sind anders. Mitigation: absolute Pfade verwenden, `/usr/bin/git` beibehalten, stdout/stderr in eigene Logs schreiben.

- **20:00 ist nicht garantiert, wenn der Mac schlaeft**  
  launchd startet nach Kalender, aber Schlaf/Wake-Verhalten kann variieren. Mitigation: App erkennt verpasste Laeufe und bietet Nachholen an.

- **UI darf nicht einfrieren**  
  Git-Scans und Dateischreiben bleiben ausserhalb des Main Actors.

- **Mehrere Installationspfade**  
  Wenn das App-Bundle neu gebaut wird, kann der LaunchAgent auf einen alten Pfad zeigen. Mitigation: Settings zeigt Agent-Status und erlaubt Reinstall; Dev-Script schreibt Plist neu.

- **Private Repo-Pfade in Logs**  
  Logs sind lokal, aber koennen sensible Pfade enthalten. Mitigation: normale UI-Meldungen knapp halten; detaillierte Pfade nur in Debug-/Log-Kontext.

## Rollback Plan

- Automatik deaktivieren:
  - `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.herrstolzier.DevDashboardFeed.daily-digest.plist`
  - eigene Plist entfernen.
- App-seitig:
  - Settings-Toggle auf aus.
  - Project-Repos bleiben gespeichert, aber keine automatischen Laeufe.
- Code-Rollback:
  - CLI/LaunchAgent/SMAppService-Dateien entfernen.
  - `AppModel.runDailyDigests` kann weiter manuell auf `DailyDigestRunner` bleiben.
- Daten-Rollback:
  - Generierte HTML-Digests liegen zentral in Application Support und koennen geloescht werden, ohne Git-Repos zu veraendern.

