# AzerothBuddyUI

Retail / Midnight. Einstieg in `Core.lua` oder `Layout.lua`. Natives Tracking mit Menü, Klick und Tooltip erhalten. CVars werden bewusst über `/abui` gesetzt.

- Mit Git-Status, TOC und relevantem Diff beginnen. Bestehende Änderungen erhalten.
- Gezielt mit `./tools/check.sh --quick` prüfen; der ZIP-Bau führt den Volltest aus. Gemeinsame Regeln im übergeordneten `AGENTS.md` beachten.
- SavedVariables, Migrationen, Slash-Befehle und Addon-Unabhängigkeit erhalten. Secret Values sowie geschützte und verbotene Frames wie bisher absichern. Neue dauerhafte Ticker, automatische CVar-Änderungen und Abhängigkeiten brauchen einen Auftrag.
- [Entwicklung und Release](DEVELOPMENT.md) bei Bedarf lesen. Veröffentlichung nur nach ausdrücklichem Auftrag.
- Nach jedem abgeschlossenen Testlauf die Antwort mit dem kopierbaren Fedora-Befehl abschließen. Für den Spieltest den Befehl aus `DEVELOPMENT.md` auch nach erfolgreicher Installation angeben.

Das Setup aktualisiert nach sichtbarer Bestätigung ausschließlich das Layout `AzerothBuddyUI`. `EditMode.Exit` verwenden und die Layoutarbeit außerhalb von Blizzards Reset ausführen. Abschluss per manuellem `/reload`. `Style.lua` mit AzerothBuddy abstimmen.
