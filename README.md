# AzerothBuddyUI 1.0.3

<p align="center"><img src="branding/icon-400.png" alt="AzerothBuddyUI" width="160" height="160"></p>

Eine übersichtliche Spieloberfläche mit eigenen Einheitentafeln, Zauberleisten, Klassenressourcen und einer geordneten Anordnung der Blizzard-UI.

**Client:** WoW Retail / Midnight · **Interface:** 120105 · **Eigenständig:** keine zusätzlichen Addons erforderlich.

**Layout-Auflösung:** Die mitgelieferte Vorlage ist für **3440 × 1440 Pixel (Ultrawide)** ausgelegt.

## Funktionen

- Minimap mit nativem Tracking und Kalender.
- Aktionsleisten, Chat und Fußleiste in einem gemeinsamen Layout.
- Spieler-, Ziel-, Fokus-, Gruppen- und Raidrahmen sowie Auren.
- Mitgeliefertes Layout für den Blizzard-Bearbeitungsmodus.

## Installation

Das Installations-ZIP unter [Releases](https://github.com/norushflow/AzerothBuddyUI/releases) herunterladen und den enthaltenen Ordner `AzerothBuddyUI` in `Interface/AddOns/` des passenden Spielclients entpacken. Die Datei `AzerothBuddyUI.toc` muss direkt in diesem Ordner liegen. Anschließend im Spiel aktivieren und `/reload` ausführen.

Für WowUp die [Repository-Adresse](https://github.com/norushflow/AzerothBuddyUI) mit Zugriff auf dieses private Repository importieren und den passenden Spielclient wählen.

## Bedienung

Auf jedem neuen Charakter und nach jedem Versionsupdate erscheint beim nächsten Login einmal pro Charakter das Setupfenster. Schließen überspringt die Einrichtung für diese Version. Im Kampf wartet das Fenster bis zum Kampfende; ein deaktiviertes UI öffnet es nur auf ausdrücklichen Aufruf.

**Vorsicht: Layout wird überschrieben!** Mit **One Button Setup** wird **AzerothBuddyUI** durch die mitgelieferte Vorlage ersetzt und ausgewählt. Eigene Änderungen an diesem Layout gehen verloren. Andere Layouts bleiben erhalten. Der Login und das bloße Öffnen des Fensters verändern keine Layoutdaten.

- `/abui on`: Setupfenster mit Überschreibwarnung öffnen.
- `/abui off`: eigenes UI deaktivieren; `/abui reset`: Positionen zurücksetzen.
- `/abui layoutstatus`: vorhandene und aktive Blizzard-Layouts anzeigen.
- `/abui`: Leisten und Abklingzeitmanager manuell einrichten.

Vor dem Setup den Blizzard-Bearbeitungsmodus schließen. Nach erfolgreicher Einrichtung **`/reload` selbst im Chat eingeben**. Das Addon löst aus der verzögerten Prüfung keinen geschützten Reload aus.

## Änderungen und Entwicklung

Die [Versionshistorie](CHANGELOG.md) enthält ausschließlich Änderungen am Addon.
Prüfungen, Paketbau und noch offene Spieltests stehen in [Entwicklung und Release](DEVELOPMENT.md).

Nach diesem Update WoW vollständig neu starten, damit das Icon in der Addonübersicht neu eingelesen wird.

Nach Installation dieses Updates WoW vollständig neu starten, damit die neue charakterbezogene Speicherung geladen wird. Der bisherige accountweite Setupstatus wird nicht übernommen; deshalb erscheint das Fenster auch auf bestehenden Charakteren einmal erneut.
