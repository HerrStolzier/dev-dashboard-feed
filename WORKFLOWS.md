# Workflow Register

## Daily Digest Development Workflow

### Zweck

Lokale HTML-Dokumente und lokale Git-Repo-Aktivitaet werden in der macOS-App als Feed angezeigt. Daily Digests entstehen aus committed Git-Aktivitaet und werden als lokale HTML-Artefakte unter Application Support gespeichert.

### Start

```bash
swift build
swift test
```

Fuer einen echten App-Start:

```bash
./script/build_and_run.sh --verify
```

Fuer den Daily-Digest-Agenten:

```bash
./script/verify_daily_digest_agent.sh
```

### Input

- lokale HTML-Dateien aus konfigurierten watched folders
- lokale Git-Repos aus `ProjectRepoStore`
- committed Git-Aktivitaet seit dem letzten erfolgreichen Crawl
- lokale Run-Metadaten und Run-History aus Application Support

### Output

- Feed-Eintraege fuer HTML-Artefakte
- generierte TurboQuant-/Pixelpunk-Daily-Digest-HTMLs
- Run-Metadaten fuer letzter Lauf, letzter Erfolg, naechster geplanter Lauf und Fehler
- Run-History-Eintraege pro Repo fuer sichtbare Status-/Fehlerlisten

### Wichtige Dateien

- `Sources/DevDashboardFeed/Stores/AppModel.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestRunner.swift`
- `Sources/DevDashboardFeed/Core/Digests/DailyDigestCommand.swift`
- `Sources/DevDashboardFeed/Core/Digests/GitActivityScanner.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestRunHistoryStore.swift`
- `Sources/DevDashboardFeed/Core/Digests/DigestRunLock.swift`
- `Sources/DevDashboardFeed/Features/Settings/SettingsView.swift`
- `Tests/DevDashboardFeedTests/DailyDigestTests.swift`
- `script/verify_daily_digest_agent.sh`
- `docs/current-status.md`
- `docs/project-learnings.md`

### Abhaengigkeiten

- macOS 15+
- Xcode 16 / Swift 6 toolchain
- `/usr/bin/git`
- launchd/LaunchAgent fuer den lokalen 20:00-Digest-MVP
- keine Produkt-Abhaengigkeit auf Codex App Server, Codex SDK, Cloud-API oder AI-Zusammenfassung

### Bekannte Fehlerfaelle

- LaunchAgent schreibt lokale Stores, aber die App aktualisiert den Feed nicht, wenn sie danach nicht neu laedt.
- Zwei Digest-Laeufe koennen ohne gemeinsamen Lock dieselben JSON-/HTML-Artefakte gleichzeitig schreiben.
- Haengende Git-Prozesse koennen den Digest-Lauf blockieren, wenn kein Timeout gesetzt ist.
- `git log --since` allein kann wegen Committer-Date statt Author-Date falsche Erwartung erzeugen.
- Direkte `file://`-Visual-QA kann in Browser-Tools blockiert sein; dann lokalen HTTP-Server verwenden.

### Pruefung

```bash
python3 scripts/agent_finish.py
```

Zusaetzlich bei Agent-/Digest-Aenderungen:

```bash
./script/verify_daily_digest_agent.sh
```

Zusaetzlich bei UI-/App-Start-Aenderungen:

```bash
./script/build_and_run.sh --verify
```

### Letzter Review

2026-05-21

## Documentation Update Workflow

### Zweck

Projektentscheidungen und Handoff-Stand werden so dokumentiert, dass ein neuer Agent ohne Chatverlauf weiterarbeiten kann.

### Start

```bash
git diff --check
python3 scripts/agent_finish.py
```

### Input

- neue Architektur- oder Produktentscheidung
- geaenderter Projektstand
- neue dauerhafte technische Erkenntnis

### Output

- aktualisiertes `docs/current-status.md`
- bei dauerhaften Erkenntnissen aktualisiertes `docs/project-learnings.md`
- bei stabilen Regeln aktualisiertes `AGENTS.md`
- bei oeffentlicher Projektuebersicht aktualisiertes `README.md`

### Wichtige Dateien

- `AGENTS.md`
- `README.md`
- `docs/current-status.md`
- `docs/project-learnings.md`
- `WORKFLOWS.md`
- `KNOWN_ERRORS.md`
- `CHECKS.md`

### Abhaengigkeiten

- keine Runtime-Abhaengigkeiten
- Schreibzugriff auf das Repo

### Bekannte Fehlerfaelle

- README, AGENTS und current-status laufen bei schnellen Richtungswechseln auseinander.
- `docs/current-status.md` wird nach einem abgeschlossenen Schritt nicht aktualisiert.
- Eine dauerhafte Erkenntnis bleibt nur im Chat und fehlt in `docs/project-learnings.md`.

### Pruefung

```bash
python3 scripts/agent_finish.py
```

### Letzter Review

2026-05-21
