# AzerothBuddyUI 1.1.1

<p align="center"><img src="branding/icon-400.png" alt="AzerothBuddyUI" width="160" height="160"></p>

Eine übersichtliche Spieloberfläche mit eigenen Einheitentafeln, Zauberleisten, Klassenressourcen und einer geordneten Anordnung der Blizzard-UI.

**Client:** WoW Retail / Midnight · **Interface:** 120105 · **Eigenständig:** keine zusätzlichen Addons erforderlich.

**Layout-Auflösung:** Die mitgelieferte Vorlage ist für **3440 × 1440 Pixel (Ultrawide)** ausgelegt.

## Funktionen

- Minimap mit nativem Tracking und Kalender.
- Aktionsleisten, Chat und Fußleiste in einem gemeinsamen Layout.
- Spieler-, Ziel-, Fokus-, Gruppen- und Raidrahmen sowie Auren.
- Mitgeliefertes Layout für den Blizzard-Bearbeitungsmodus.

## Sprachen und aktueller Stand

Die Spielsprache bestimmt die Texte: Deutsch (`deDE`), Englisch (`enUS`, `enGB`), sonst Englisch. Die gemeinsame Codebasis lädt `Locales/enUS.lua` und anschließend die deutschen Übersetzungen. Namen aus Blizzard-APIs (z. B. Gegenstände, Zauber und Klassen) folgen weiterhin der Clientsprache.

- Account-SavedVariable auf `AzerothBuddyUI` umgestellt. Vorhandenes `ScreenshotUIDB` wird beim Login übernommen, sofern noch keine neue Datenbank besteht.
- Charakterbezogene Setup-Bestätigung bleibt erhalten.

Die bisherige SavedVariables-Datei muss beim ersten Start noch vorhanden sein. Bereits vorhandene neue Einstellungen haben Vorrang. Nach dem nächsten Logout wird nur noch `AzerothBuddyUI` geschrieben; `AzerothBuddyUICharDB` bleibt unverändert. Vor dem Update kann die alte Datei im WTF-Ordner gesichert werden.

## Installation

Das Installations-ZIP unter [Releases](https://github.com/norushflow/AzerothBuddyUI/releases) herunterladen und den enthaltenen Ordner `AzerothBuddyUI` in `Interface/AddOns/` des passenden Spielclients entpacken. Die Datei `AzerothBuddyUI.toc` muss direkt in diesem Ordner liegen. Anschließend im Spiel aktivieren und `/reload` ausführen.

Für WowUp die [Repository-Adresse](https://github.com/norushflow/AzerothBuddyUI) importieren und den passenden Spielclient wählen.

## Schrift

Eine für den Einsatz im Spiel lizenzierte Expressway-Regular-Datei im TrueType-Format kann lokal unter `AzerothBuddyUI/Media/Expressway.ttf` im installierten Addon abgelegt werden. Nach einem Neustart verwendet AzerothBuddyUI sie für eigene Dialoge, Tooltips und weitere Texte im gemeinsamen Design. Ohne verwendbare Datei sowie im koreanischen und chinesischen Client greift das Addon auf die Schrift des Clients zurück. Einheitentafeln und Raid-Vorschau verwenden die Schrift und den Schatten aus Version 1.0.7. [Lizenzinformationen von Typodermic](https://typodermicfonts.com/license/).

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
