# Dev Dashboard Feed

Native macOS app that turns local HTML docs into a calm, visual developer feed.

## Why This Exists

Developer information is usually scattered across generated docs, changelogs,
release notes, and half-open browser tabs. This project explores a quieter
alternative: keep local HTML artifacts on disk, index the useful metadata, and
present them like a focused reading feed instead of a noisy browser session.

The goal is not another documentation site. The goal is a calm desk for
developer reading.

## Current Status

This repository contains a working SwiftUI macOS foundation with:

- a feed/detail/settings structure
- a native watched-folder picker with persisted folder access
- recursive HTML scanning for watched folders
- sample-data fallback when no watched folders are configured
- local HTML preview in the detail view through `WKWebView`
- safer preview navigation for local files and external links
- fixture HTML documents with relative CSS, JavaScript, and SVG assets
- unit and WebKit probe tests for the scanner and preview flow
- a script that builds and starts a real `.app` bundle

The current handoff docs live in:

- `docs/current-status.md`
- `docs/project-learnings.md`

The broader product plan lives next to this repository at:

- `../dev-dashboard-feed-plan.md`

## Product Direction

The app should:

- watch local folders with HTML files
- turn files into feed items
- show previews and a readable detail view
- highlight explanation blocks like "Erklaerbaer"
- feel native on macOS

The app should not become a CMS or mutate the source HTML files. HTML documents
stay as source artifacts; the app adds index, metadata, preview, and reading
flow around them.

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

1. Add a file watcher so created, changed, renamed, and deleted HTML files
   refresh without relaunch.
2. Add search, filters, and sort modes for the feed.
3. Do a visible desktop click test for local preview navigation and visual
   polish.
4. Check large HTML files for UI pauses.

## Project Workflow

This project uses a strict handoff standard:

1. After each completed step, update `docs/current-status.md`.
2. If the step revealed a durable lesson, update `docs/project-learnings.md`.
3. A new agent should be able to continue from the docs plus the code alone.

## License

MIT
