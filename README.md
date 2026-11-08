# AzerothBuddyUI 1.0.3

<p align="center"><img src="branding/icon-400.png" alt="AzerothBuddyUI" width="160" height="160"></p>

Eine übersichtliche Spieloberfläche mit eigenen Einheitentafeln, Zauberleisten, Klassenressourcen und einer geordneten Anordnung der Blizzard-UI.

**Client:** WoW Retail / Midnight · **Interface:** 120105 · **Eigenständig:** keine zusätzlichen Addons erforderlich.

## Funktionen

- Minimap mit nativem Tracking und Kalender.
- Aktionsleisten, Chat und Fußleiste in einem gemeinsamen Layout.
- Spieler-, Ziel-, Fokus-, Gruppen- und Raidrahmen sowie Auren.
- Mitgeliefertes Layout für den Blizzard-Bearbeitungsmodus.

## Installation

Das Installations-ZIP unter [Releases](https://github.com/norushflow/AzerothBuddyUI/releases) herunterladen und den enthaltenen Ordner `AzerothBuddyUI` in `Interface/AddOns/` des passenden Spielclients entpacken. Die Datei `AzerothBuddyUI.toc` muss direkt in diesem Ordner liegen. Anschließend im Spiel aktivieren und `/reload` ausführen.

Für WowUp die [Repository-Adresse](https://github.com/norushflow/AzerothBuddyUI) mit Zugriff auf dieses private Repository importieren und den passenden Spielclient wählen.

## Bedienung

Beim ersten Login nach Installation dieses Updates erscheint einmalig pro Account ein Willkommensfenster. **One Button Setup** führt `/abui on` aus. Schließen überspringt den Dialog; der Befehl bleibt jederzeit verfügbar. Im Kampf wird das Fenster erst nach Kampfende angezeigt.

- `/abui`: Leisten und Abklingzeitmanager manuell einrichten.
- `/abui on`: Layout aktivieren und die mitgelieferte Vorlage auswählen; anschließend wird die Oberfläche neu geladen.
- `/abui off`: eigenes Layout deaktivieren; `/abui reset`: Positionen zurücksetzen.
- `/abui layoutstatus`: vorhandene und aktive Blizzard-Layouts anzeigen.

Den Blizzard-Bearbeitungsmodus vor `/abui on` schließen. Ein vorhandenes Layout namens **AzerothBuddyUI** wird wiederverwendet; eigene Änderungen bleiben erhalten. Beim Login erfolgen kein Layoutimport und keine automatische Änderung der Spieloptionen.

## Änderungen und Entwicklung

Die [Versionshistorie](CHANGELOG.md) enthält ausschließlich Änderungen am Addon.
Prüfungen, Paketbau und noch offene Spieltests stehen in [Entwicklung und Release](DEVELOPMENT.md).

Nach diesem Update WoW vollständig neu starten, damit das Icon in der Addonübersicht neu eingelesen wird.

`/abui on` bestätigt die tatsächliche Layoutauswahl nach dem Import, bevor die Oberfläche neu lädt. Bei nicht bestätigter Auswahl bleibt ein Reload aus; die Einrichtung kann erneut gestartet werden.
