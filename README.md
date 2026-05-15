# Dev Dashboard Feed

Native macOS app that turns local HTML docs and Git project activity into a
colorful, personal project feed.

## Why This Exists

Developer information is usually scattered across generated docs, changelogs,
release notes, Git commits, and half-open browser tabs. This project turns that
local material into a private Devboard: a colorful Social-Media-style timeline
for your own projects.

The goal is not another documentation site or CMS. The goal is a local-first
project feed that makes recent work visible, energetic, and easy to re-enter.

## Current Status

This repository contains a working SwiftUI macOS foundation with:

- a feed/detail/settings structure
- a native watched-folder picker with persisted folder access
- recursive HTML scanning for watched folders
- saved local Git project repos
- manual Daily Digest generation from committed Git activity
- a 20:00 LaunchAgent MVP with install, uninstall, and kickstart flows
- generated TurboQuant-style Daily Digest HTML posts
- run metadata for last run, last success, next scheduled run, and errors
- sample-data fallback when no watched folders are configured
- local HTML preview in the detail view through `WKWebView`
- safer preview navigation for local files and external links
- fixture HTML documents with relative CSS, JavaScript, and SVG assets
- unit and WebKit probe tests for the scanner and preview flow
- a script that builds and starts a real `.app` bundle

The current handoff docs live in:

- `docs/current-status.md`
- `docs/project-learnings.md`

The active implementation plan lives in:

- `daily-digest-background-agent-plan.md`

An older broader product plan also exists next to this repository:

- `../dev-dashboard-feed-plan.md`

## Product Direction

The app should:

- watch local folders with HTML files
- manage local Git repos as project sources
- turn files into feed items
- create colorful Daily Digest posts from Git commits
- show previews and a readable detail view
- highlight explanation blocks like "Erklaerbaer"
- feel native on macOS
- use a Pixelpunk/Game-HUD visual direction: dark, colorful, playful, slightly
  pixel-like, and project-centered

The app should not become a CMS or mutate the source HTML files. HTML documents
and Git repos stay as source artifacts; the app adds index, metadata, preview,
Daily Digest HTML, and feed presentation around them.

## Documentation Map

- `README.md`: public overview, build steps, and plan summary.
- `AGENTS.md`: stable project rules, architecture direction, and workflow.
- `docs/current-status.md`: current handoff state for the next development step.
- `docs/project-learnings.md`: durable technical learnings and recurring gotchas.
- `daily-digest-background-agent-plan.md`: detailed phased plan for the 20:00
  Daily Digest automation.

## Plan Summary

There are two plans in the project history. The older broader plan at
`../dev-dashboard-feed-plan.md` describes the original app direction: build a
native SwiftUI macOS feed for local HTML documents, add folder scanning,
preview, search, filters, reading state, Erklaerbaer extraction, and native
polish.

The active plan in this repository is `daily-digest-background-agent-plan.md`.
It focuses on turning the manual Daily Digest feature into a real local 20:00
automation:

1. Separate the Digest runtime so the app, CLI, tests, and background agent use
   the same code.
2. Add a one-shot CLI mode, `--run-digests-once`, that can run without opening
   the SwiftUI window.
3. Generate and install a local LaunchAgent that starts the CLI mode at 20:00.
4. Evaluate whether an embedded `SMAppService` helper is worth adding after the
   LaunchAgent MVP is proven.
5. Show automation status in Settings: installed state, last run, last success,
   next scheduled run, errors, and missed-run catch-up.
6. Verify end to end with a temporary Git repo, generated Digest HTML, app
   launch checks, and browser visual QA.

Current plan status: the shared runtime, CLI mode, LaunchAgent MVP, run
metadata, Settings status, E2E script, and browser QA path are implemented.
The next practical checkpoint is to use the Agent MVP with a real personal repo
inside the running app, then decide whether `SMAppService` is still needed or
whether the next product step should be the HTML folder file watcher.

## Visual Direction

The current design target is **Pixelpunk Devboard**. It keeps the dark
TurboQuant base, but adds a playful game-interface layer inspired by the
current mockup direction:

- the whole app reads as a small Pixel-OS, not a normal app with pixel accents
- the main surface uses one outer frame with integrated chrome and actions
- project cards feel like quest cards or cartridges
- Daily Digests read like quest logs
- badges use `LVL`, `XP`, status, and artifact language
- panels use sharp, pixel-like corners instead of soft document cards
- neon cyan, magenta, green, and amber carry project energy
- pixel/game flavor supports the information instead of replacing readability

The UI should not become a full retro emulator skin. The intended balance is a
modern native macOS app with game-HUD energy.

## Requirements

- macOS 15 or newer
- Xcode 16 or newer, including the Swift 6 toolchain

## Build And Test

```bash
swift build
swift test
```

To build and launch the macOS app bundle:

```bash
./script/build_and_run.sh
```

To run a quick launch check with the included preview fixtures:

```bash
./script/build_and_run.sh --verify \
  --watched-folder "$PWD/Fixtures/PreviewManual" \
  --selected-document "$PWD/Fixtures/PreviewManual/index.html"
```

## Near-Term Next Steps

1. Use the Agent MVP with a real personal repo in the running app: choose repo,
   install agent, kickstart it, and confirm the Digest appears in the feed.
2. Decide whether to keep the LaunchAgent MVP as the automation path or invest
   in an embedded `SMAppService` helper.
3. Add a file watcher so created, changed, renamed, and deleted HTML files
   refresh without relaunch.
4. Add search, filters, and sort modes for the feed.
5. Check large HTML files and larger Git histories for UI pauses.

## Project Workflow

This project uses a strict handoff standard:

1. After each completed step, update `docs/current-status.md`.
2. If the step revealed a durable lesson, update `docs/project-learnings.md`.
3. A new agent should be able to continue from the docs plus the code alone.

## License

MIT
