#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DevDashboardFeed"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/devboard-agent-verify.XXXXXX")"

cleanup() {
  rm -rf "$TEMP_ROOT"
}

if [[ "${KEEP_TEMP:-0}" == "1" ]]; then
  echo "Keeping verification temp directory: $TEMP_ROOT"
else
  trap cleanup EXIT
fi

REPO_DIR="$TEMP_ROOT/repo"
DIGEST_DIR="$TEMP_ROOT/digests"
STORE_FILE="$TEMP_ROOT/project-repos.json"
METADATA_FILE="$TEMP_ROOT/digest-run-metadata.json"
HISTORY_FILE="$TEMP_ROOT/digest-run-history.json"
LOCK_FILE="$TEMP_ROOT/daily-digest.lock"
NOW="2026-05-06T20:00:00Z"

mkdir -p "$REPO_DIR" "$DIGEST_DIR"
git -C "$REPO_DIR" init >/dev/null
git -C "$REPO_DIR" config user.name "Devboard Verify"
git -C "$REPO_DIR" config user.email "devboard-verify@example.test"

printf 'daily proof\n' >"$REPO_DIR/proof.txt"
git -C "$REPO_DIR" add proof.txt
GIT_AUTHOR_DATE="2026-05-06T19:30:00Z" \
GIT_COMMITTER_DATE="2026-05-06T19:30:00Z" \
  git -C "$REPO_DIR" commit -m "Verify daily digest agent" >/dev/null

REPO_ID="11111111-1111-1111-1111-111111111111"
cat >"$STORE_FILE" <<JSON
[
  {
    "accentColor" : "#38bdf8",
    "id" : "$REPO_ID",
    "isActive" : true,
    "lastSuccessfulCrawlAt" : null,
    "name" : "verify-repo",
    "path" : "$REPO_DIR"
  }
]
JSON

swift build --package-path "$ROOT_DIR" >/dev/null
BUILD_BINARY="$(swift build --package-path "$ROOT_DIR" --show-bin-path)/$APP_NAME"

"$BUILD_BINARY" \
  --run-digests-once \
  --project-repo-store "$STORE_FILE" \
  --digest-output-root "$DIGEST_DIR" \
  --digest-metadata-store "$METADATA_FILE" \
  --digest-history-store "$HISTORY_FILE" \
  --digest-lock "$LOCK_FILE" \
  --digest-now "$NOW"

DIGEST_FILE="$DIGEST_DIR/verify-repo-11111111/2026-05-06.html"
test -f "$DIGEST_FILE"
grep -q "Verify daily digest agent" "$DIGEST_FILE"
grep -q "background: #0a0a0f" "$DIGEST_FILE"
grep -q "lastSuccessfulCrawlAt" "$STORE_FILE"
grep -q "lastRunAt" "$METADATA_FILE"
grep -q "verify-repo" "$HISTORY_FILE"
grep -q "created" "$HISTORY_FILE"

echo "Verified Daily Digest CLI against temporary Git repo: $DIGEST_FILE"
