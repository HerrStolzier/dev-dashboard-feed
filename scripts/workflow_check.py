#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "AGENTS.md",
    "WORKFLOWS.md",
    "KNOWN_ERRORS.md",
    "CHECKS.md",
    "scripts/workflow_check.py",
    "scripts/agent_finish.py",
]
WORKFLOW_HEADINGS = [
    "Zweck",
    "Start",
    "Input",
    "Output",
    "Wichtige Dateien",
    "Abhaengigkeiten",
    "Bekannte Fehlerfaelle",
    "Pruefung",
    "Letzter Review",
]
GUARD_DOCS = [
    "WORKFLOWS.md",
    "KNOWN_ERRORS.md",
    "CHECKS.md",
]


def run_check(command: list[str]) -> str | None:
    result = subprocess.run(command, cwd=ROOT)
    if result.returncode != 0:
        return "failed: " + " ".join(command)
    return None


def has_placeholder_todo(text: str) -> bool:
    patterns = [
        re.compile(r"^\s*TODO\b", re.MULTILINE),
        re.compile(r"TODO:\s+", re.MULTILINE),
        re.compile(r"-\s+TODO\b", re.MULTILINE),
    ]
    return any(pattern.search(text) for pattern in patterns)


def main() -> int:
    failures = []
    for relative in REQUIRED:
        if not (ROOT / relative).exists():
            failures.append(f"missing: {relative}")

    workflow_text = (ROOT / "WORKFLOWS.md").read_text(encoding="utf-8") if (ROOT / "WORKFLOWS.md").exists() else ""
    for heading in WORKFLOW_HEADINGS:
        if f"### {heading}" not in workflow_text:
            failures.append(f"WORKFLOWS.md missing section: {heading}")

    for relative in GUARD_DOCS:
        path = ROOT / relative
        if path.exists() and has_placeholder_todo(path.read_text(encoding="utf-8")):
            failures.append(f"unresolved TODO in {relative}")

    for command in [
        ["swift", "build"],
        ["swift", "test"],
        ["git", "diff", "--check"],
    ]:
        failure = run_check(command)
        if failure:
            failures.append(failure)

    if failures:
        print("Workflow Guard Check: FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Workflow Guard Check: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
