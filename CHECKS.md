# Workflow Checks

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
- Do not add CI, hooks, global tools, Codex App Server, or Codex SDK as product dependencies unless explicitly requested and documented.
