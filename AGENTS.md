# AzerothBuddyUI

Retail / Midnight. Einstieg in `Core.lua`, `Layout.lua` oder das betreffende UI-Modul. Natives Tracking mit Originalmenü, Klick und Tooltip erhalten. CVars werden über `/abui` bewusst gesetzt.

- `git status --short` und TOC zuerst prüfen. Nur relevante Dateien und Tests lesen. Lokale Änderungen erhalten und Diffs prüfen.
- `./tools/check.sh --quick` für gezielte Iteration, `./tools/check.sh --full` für den Abschluss. Bei Fehlern oder Bedarf `--debug` verwenden.
- SavedVariables, Migrationen, Slash-Befehle und Addon-Unabhängigkeit erhalten. Secret Values vor Lua-Operationen prüfen und bestehende Guards für Kampf, geschützte und verbotene Frames beibehalten.
- Keine neuen dauerhaften Ticker, automatischen CVar-Änderungen oder Abhängigkeiten ohne Auftrag. UI, Kampf und Taint im Zielclient prüfen.
- Release-Ablauf in `DEVELOPMENT.md`. Version, Push, Tag und Veröffentlichung nur nach ausdrücklichem Auftrag. Veröffentlichungsziel `norushflow/AzerothBuddyUI`.
- `TEMP/UEBERGABE.md` hält lokal Ziel, Änderungen, Prüfstatus und nächsten Schritt fest.

Setup bestätigt je Charakter und Version. Erst der sichtbare Setup-Klick überschreibt die eigene Vorlage. Andere Layouts erhalten. `EditMode.Exit` verwenden und Layoutarbeit außerhalb von Blizzards Reset ausführen. Der Abschluss fordert zum manuellen `/reload` auf.
Nach lieferbaren Änderungen ein lokales Installationspaket erstellen. Ältere Pakete bei beauftragter Bereinigung außerhalb des Repositories archivieren.
