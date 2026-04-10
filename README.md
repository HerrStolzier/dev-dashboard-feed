# Dev Dashboard Feed

Native macOS app that turns local HTML docs into a calm, visual developer feed.

## Why this exists

Developer information is usually scattered across docs pages, release notes, changelogs, and half-open browser tabs. This project explores a quieter alternative: pull local HTML documentation into one place, extract the important bits, and present them like a focused reading feed instead of a noisy browser session.

## Core Product Idea

Dev Dashboard Feed should help you:

- watch one or more local documentation folders
- detect fresh or changed HTML files
- extract titles, sections, dates, and summaries
- group related updates into a readable feed
- open the source doc instantly when you want the full context

The goal is not another tab jungle. The goal is a calm desk for developer reading.

## Product Principles

- **Local first**: your docs stay on your machine
- **Quiet by default**: signal over noise
- **Readable in one glance**: strong hierarchy, not dashboard clutter
- **Explainable**: summaries should always link back to source material
- **Useful before clever**: the feed should already be valuable before adding fancy AI layers

## Planned Experience

1. Point the app at a folder of exported docs or HTML files.
2. The app indexes pages and tracks what changed.
3. New updates show up as clean cards with context, source, and timestamps.
4. You skim the feed, mark items as read, and jump into the original doc when needed.

## Planned Stack

- SwiftUI for the main interface
- AppKit interop where macOS-specific behavior needs it
- local parsing and indexing
- optional semantic grouping or summarization later

## Status

This repo is in the concept-and-direction stage.

That means the most important thing here right now is a sharp product definition:

- what the app should feel like
- what problems it should solve first
- what *not* to turn into unnecessary complexity

## First Milestones

- [ ] define the first-run user flow
- [ ] decide which HTML sources to support first
- [ ] design the feed card anatomy
- [ ] add a first local parser + indexer
- [ ] build the initial macOS reading interface

## License

MIT
