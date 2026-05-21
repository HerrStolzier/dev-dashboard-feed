#!/usr/bin/env python3
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    result = subprocess.run([sys.executable, "scripts/workflow_check.py"], cwd=ROOT)
    log_dir = ROOT / ".agents"
    log_dir.mkdir(exist_ok=True)
    status = "OK" if result.returncode == 0 else "FAIL"
    with (log_dir / "workflow_guard_runs.md").open("a", encoding="utf-8") as file:
        file.write(f"## {datetime.now(timezone.utc).isoformat()} - {status}\n\n")
        file.write("- command: python3 scripts/agent_finish.py\n\n")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
