# AGENTS.md

## Projekt

`dev-dashboard-feed`

Native macOS-App, die lokale HTML-Dokumente und Git-Projektaktivitaet als bunten, persoenlichen Projekt-Feed anzeigt.
Die App ist kein Wiki und kein CMS. Sie ist ein local-first Devboard fuer generierte HTML-Artefakte und lokale Daily-Digests.

## Zielbild

Die App soll:

- lokale HTML-Dateien beobachten
- lokale Git-Repos als Projektquellen verwalten
- daraus Feed-Eintraege bauen
- aus Git-Commits farbige Daily-Digest-HTMLs im TurboQuant-Stil erzeugen
- gute Vorschauen und eine Vollansicht anbieten
- Erklaerbaer-Bloecke erkennen und hervorheben
- sich wie eine native macOS-App anfuehlen

## Produktidee in einem Satz

Wie ein privates, buntes Social-Media-Devboard fuer eigene Projekte, nur lokal, ohne Serverpflicht und ohne Cloud-Zusammenfassung.

## Wichtige Referenzen

- Plan-Datei: `/Users/clawdkent/Desktop/projekte-codex/dev-dashboard-feed-plan.md`
- Repo: `https://github.com/HerrStolzier/dev-dashboard-feed`
- Aktueller Arbeitsstand: `docs/current-status.md`
- Dauerhafte Learnings: `docs/project-learnings.md`

## Aktueller Stand

- SwiftUI-macOS-App-Skeleton ist vorhanden.
- Feed-, Detail-, Settings- und Menu-Bar-Struktur stehen.
- Ein nativer Folder-Picker mit gespeichertem Ordnerzugriff ist eingebaut.
- HTML-Dateien aus beobachteten Ordnern werden bereits rekursiv gescannt und als Feed-Eintraege angezeigt.
- Lokale HTML-Dateien werden in der Detailansicht per `WKWebView` angezeigt.
- Project-Repos koennen gespeichert werden.
- Manuelle Daily-Digests aus lokalen Git-Commits werden als TurboQuant-Style-HTML erzeugt und im Feed angezeigt.

## Architektur-Richtung

- `SwiftUI` zuerst
- `AppKit` nur dort, wo macOS-Integration wirklich gebraucht wird
- HTML-Dateien bleiben unveraenderte Quellartefakte
- Git-Repos bleiben ebenfalls unveraendert; generierte Digests liegen zentral in Application Support
- Die App legt nur Index, Metadaten, Preview und Feed-Darstellung darueber
- Erst kleine, belastbare Schritte. Keine grossen Umbrueche ohne echten Bedarf.

## Was als Naechstes wichtig ist

1. echten 20:00-Background-Agent sauber paketieren und registrieren
2. danach robuster File-Watcher fuer Aenderungen in HTML-Ordnern
3. danach bessere Metadaten, Filter und Suchlogik
4. danach staerkeres UI-Polish im TurboQuant-/Social-Feed-Stil

## Nicht aus Versehen in die falsche Richtung laufen

- Nicht sofort Editor-Funktionen bauen
- Nicht wie eine Doku-Website oder einen stillen Reader denken
- Nicht zuerst Animationen priorisieren, bevor der lokale Projektfluss stabil ist
- Nicht HTML-Dateien mutieren oder umschreiben
- Nicht Git-Repos beschreiben oder Working-Tree-Dateien als Digest-Quelle verwenden
- Keine grosse Architektur ausdenken, wenn ein kleiner lokaler Schritt reicht

## UX-Leitlinien

- bunt
- persoenlich
- projektzentriert
- schnell lesbar
- lebendige Standardansicht fuer "was ist in meinen Projekten passiert?"

Die App soll wie ein privates Projekt-Social-Feed wirken: farbig, energievoll und trotzdem lokal beherrschbar.

## Technische Stolpersteine

- Ordnerzugriff und Wiederherstellung ueber App-Neustarts
- File-Watcher-Event-Flut bei vielen generierten Dateien
- HTML-Preview mit relativen Assets
- grosse Dateien ohne ruckelige UI
- Parser-Regeln fuer Erklaerbaer-Hinweise nicht zu locker machen
- Git-Datumslogik: fuer Daily-Digests Author-Dates bewusst filtern, statt blind auf `git log --since` zu vertrauen
- Background-Agent sauber von manuellen App-Laeufen trennen; keine Schein-Automatik einbauen

## Arbeitsstandard fuer dieses Projekt

Jeder groessere Arbeitsschritt soll standardmaessig diese vier Teile enthalten:

1. eigentliche Implementierung
2. kleiner Refactor-Blick auf die betroffenen Dateien
3. Security-Sanity-Check fuer den neuen Fluss
4. ehrliche Verifikation mit Build, Tests und wenn sinnvoll einem echten App-Start

Wenn etwas davon in einer Runde nicht sinnvoll oder nicht moeglich ist, muss das im Abschluss klar benannt werden.

## Session-Abschluss-Standard

Das ist in diesem Projekt verpflichtend:

- Nach jedem abgeschlossenen Schritt muss `docs/current-status.md` aktualisiert werden.
- Wenn dabei eine neue dauerhafte Erkenntnis entstanden ist, muss auch `docs/project-learnings.md` aktualisiert werden.
- Ein neuer Agent soll den Stand allein ueber diese Dokumente und den Code verstehen koennen, ohne den Chatverlauf zu brauchen.

`docs/current-status.md` soll immer mindestens diese Punkte enthalten:

- was zuletzt abgeschlossen wurde
- was jetzt technisch wirklich im Repo existiert
- wie der Stand verifiziert wurde
- was als naechster kleinster sinnvoller Schritt empfohlen ist
- welche Risiken, Luecken oder offenen Entscheidungen gerade wichtig sind

## Dokument-Rollen

- `AGENTS.md`: stabile Regeln, Arbeitsweise, Architektur-Richtung und Projektgrenzen
- `docs/current-status.md`: aktueller Uebergabe-Stand fuer den naechsten Agent
- `docs/project-learnings.md`: langlebige technische Learnings und wiederkehrende Stolpersteine

## Empfehlung fuer den naechsten Agent

Beginne immer mit `docs/current-status.md`.

Wenn der dort empfohlene naechste Schritt noch sinnvoll ist, setze genau dort an.
Wenn du bewusst davon abweichst, schreibe kurz in `docs/current-status.md`, warum sich die Prioritaet geaendert hat.
