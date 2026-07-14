# Known Errors

> **Zweck:** Bekannte Fehler der Dashboard-App und des Guard-Setups.
> **Scope:** LaunchAgent-Zustand, Digest-Races, Guard-Installation.
> **Suchbegriffe:** python, launchagent, stale, digest, race, concurrent, guard
> **Stand:** 2026-07-14

This file tracks real, understood errors and their fixes. Do not add speculative issues here; use `docs/current-status.md` for open risks.

## `python` command not found when installing the workflow guard

### Symptom

Running the guard bootstrap with `python` failed:

```text
zsh:1: command not found: python
```

### Ursache

This macOS environment exposes Python as `python3`, not `python`.

### Loesung

Use `python3` for guard commands:

```bash
# Claude-Portierung des Workflow-Guard-Systems:
python3 /Users/ten.december/claude-projects/workflow-guard-system/plugin/scripts/bootstrap_guard.py --root .
python3 scripts/agent_finish.py
```

## LaunchAgent writes state but the running app looks stale

### Symptom

The Daily Digest agent completes successfully, but the feed does not show the new Digest until the app reloads local stores.

### Ursache

The LaunchAgent writes repo state, run metadata, run history, and Digest HTML outside the running `AppModel` instance.

### Loesung

After kickstart, the app polls local stores and reloads repo state, run metadata, run history, and Digest documents.

## Concurrent Digest runs can race on local artifacts

### Symptom

Manual app run and LaunchAgent run can both try to write repo JSON, metadata JSON, history JSON, or Digest HTML.

### Ursache

Both processes operate on the same local Application Support files.

### Loesung

Use `DigestRunLock` so app and CLI/LaunchAgent respect the same non-blocking file lock.

## Hung Git process blocks Daily Digest

### Symptom

A Digest run can appear stuck while reading a repo.

### Ursache

External Git processes can hang or become very slow on damaged, locked, or unusual repos.

### Loesung

`GitActivityScanner` runs Git with a timeout and reports a clear timeout error.

## `git log --since` can disagree with expected authored dates

### Symptom

A test or Digest run can include/exclude commits unexpectedly when using historical commit dates.

### Ursache

Git filtering can be influenced by committer dates; the product cares about author dates for Daily Digest logic.

### Loesung

Use Git to narrow the candidate set, then parse and filter author dates in Swift.
