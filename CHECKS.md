# Workflow Checks

> **Zweck:** Checks fuer dev-dashboard-feed: Standardabschluss und gezielte Checks.
> **Scope:** swift build, swift test, git diff --check.
> **Suchbegriffe:** swift, build, test, git diff, targeted, guard-dateien
> **Stand:** 2026-07-14

## Standard Finish Check

Run this before claiming that non-trivial work is complete:

```bash
python3 scripts/agent_finish.py
```

The finish check verifies:

- required guard files exist
- `WORKFLOWS.md` has the expected workflow sections
- guard docs do not contain unresolved `TODO` placeholders
- `swift build` passes
- `swift test` passes
- `git diff --check` passes

## Targeted Checks

Daily Digest / LaunchAgent changes:

```bash
./script/verify_daily_digest_agent.sh
```

App launch or UI-sensitive changes:

```bash
./script/build_and_run.sh --verify
```

Generated HTML visual QA:

```bash
python3 -m http.server 8765
```

Then open the generated HTML through the in-app browser or another browser tool.

## Required Guard Files

- `CLAUDE.md`
- `AGENTS.md`
- `WORKFLOWS.md`
- `KNOWN_ERRORS.md`
- `CHECKS.md`
- `scripts/workflow_check.py`
- `scripts/agent_finish.py`

## Documentation Rules

- Update `docs/current-status.md` after each completed step.
- Update `docs/project-learnings.md` when a durable lesson is learned.
- Update `WORKFLOWS.md`, `KNOWN_ERRORS.md`, or `CHECKS.md` when workflows, known failure modes, or verification commands change.
- Do not add CI, hooks, global tools, cloud AI services, or agent SDKs as product dependencies unless explicitly requested and documented.

## Standardabschluss

```bash
python3 scripts/agent_finish.py --auto-claims
```

Fuehrt aus:
1. Struktur-Guard (`scripts/workflow_check.py`) - kanonisch, in allen Repos identisch
2. Technischer Projektcheck aus `.agents/project_check`
3. Claim-Check (`scripts/claim_check.py`)

Exit 2 blockiert ueber den Stop-Hook den Abschluss.
