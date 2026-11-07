# AzerothBuddyUI 1.0.1 – WoW Retail

## Entwicklung unter Linux

Öffne diesen Repository-Ordner in Codex oder starte hier `opencode`. Die Projektregeln stehen in [AGENTS.md](AGENTS.md).

- Fedora-Pakete bei Bedarf installieren mit `sudo dnf install luajit zip unzip`.
- `./tools/check.sh` prüft TOC-Dateipfade, Lua-Syntax und die vorhandenen Funktionstests.
- `./tools/package.sh` erstellt nach grüner Prüfung ein lokales Installations-ZIP unter `dist/`. Entpacke den darin enthaltenen Addon-Ordner zur Prüfung in den passenden WoW-Client und führe `/reload` aus.

### Release für WowUp

Für einen beauftragten Release die Version in der TOC, im README-Titel und in
vorhandenen Versionsmeldungen abgleichen. Den geprüften Stand auf `main` hochladen
und einen passenden Git-Tag setzen, etwa `git tag v1.2.3` und
`git push origin v1.2.3`. Die GitHub Action **WowUp Release** führt die Tests
aus, baut das Installations-ZIP und veröffentlicht es im privaten Repository.
In WowUp den passenden Spielclient auswählen und die Repository-URL importieren.
Der WowUp-Zugriffstoken benötigt Leserechte für dieses Repository.

Eigenständiges WoW-Retail-/Midnight-UI-Addon (ohne ElvUI und ohne
Laufzeitabhängigkeit zu AzerothBuddy). Zuständig für Blizzard-UI-Anordnung:
Minimap, Blizzard-Tracking-Symbol, Kalender, Aktionsleisten, Chat, Fußleiste,
Gruppen-/Unitframes und weitere bereits vorhandene UI-Elemente.

## Installation und Bedienung

- Ordner `AzerothBuddyUI` nach `World of Warcraft/_retail_/Interface/AddOns/`
  kopieren; `.toc` muss direkt in `AddOns/AzerothBuddyUI/` liegen.
- In WoW aktivieren und `/reload`. `/abui` ist die **manuelle**
  Einrichtung der Leisten 2–4 und des Abklingzeitmanagers; kein automatisches
  Ändern von CVars beim Login.
- `/abui reset`: Layoutpositionen zurücksetzen;
  `/abui off` / `/abui on`: eigenes Layout ausschalten/einschalten.
- Die Layoutpositionen verwaltet das Addon; ein manuelles Verschieben über
  Slash-Befehle ist nicht vorgesehen.

## Minimap und Tracking

- Quadratische Minimap (240 × 240) oben rechts, Kalender oben rechts.
- **Blizzard-Tracking-Symbol oben links:** Original-Frame und Blizzard-Menü,
  Klick- und Tooltip-Verhalten bleiben erhalten. Größe orientiert sich am Kalender.
- Das Symbol nicht über `hideNative(MinimapCluster.Tracking)` ausblenden;
  keine eigene Tracking-Implementierung in AzerothBuddy anlegen.
- Layout-/Skalierungsänderungen und Kampf-/EditMode-Grenzen beachten.

## Formen-/Haltungs- und Begleiterleiste – 1.0.1

- Buttons übernehmen Breite/Höhe einschließlich Skalierung von Leiste 4 (MultiBarRightButton1) statt fester 28 × 28 Punkte.
- Bisherige Anker und zwei Punkte Button-Abstand bleiben erhalten; die Gesamtbreite folgt der Buttonanzahl.
- Native Layoutänderungen von Leiste 4 aktualisieren die Größen mit. Kampf- und Fremdframe-Schutz bleiben bestehen.
- Automatische Tests einschließlich abweichender Referenzskalierung erfolgreich; Optik und EditMode im Client noch prüfen.
- check.sh insgesamt Exit 1 wegen vorhandener abweichender Release-ZIPs; keine Archive verändert.

## Projektstand und Prüfung

- **Aktive Basis:** `AzerothBuddyUI-1.0.1/AzerothBuddyUI/`.
- **Tests:** `TEMP/AzerothBuddyUI-1.0.1/tests/` (außerhalb des Addonordners).
- **Prüfung:** von der Projektwurzel `./tools/check.sh` ausführen.
- Am 01.11.2026 meldete der Benutzer: automatisierte Projektprüfung erfolgreich;
  die Tracking-Korrektur funktionierte im WoW-Client vor dem Versionsneustart.
  Umfangreiche Live-Taint-, Kampf-, Klassen- und Raidtests sind dadurch nicht belegt.
- Am 02.11.2026 wurde die manuelle Verschiebefunktion entfernt; die normale
  Layoutpositionierung bleibt unverändert.
- Ein Release-ZIP für 1.0.0 wurde nicht erstellt.
- Designregeln: [UI-REFERENZEN.md](../../UI-REFERENZEN.md).

## Historie

[README-UI-HISTORIE.md](../../docs/README-UI-HISTORIE.md) enthält die früheren
Versionsabschnitte mit ihrem jeweiligen damaligen Stand. Nicht als aktuelle
Aufgabenliste verwenden.

**Regel für neue Änderungen:** Erst `AGENTS.md` lesen. Für Codeänderungen
neue Patch-Version (nächste `1.0.1`) als vollständige Versionskopie erstellen;
1.0.0 unverändert lassen.
