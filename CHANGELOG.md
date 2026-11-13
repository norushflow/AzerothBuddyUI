# Changelog

## 1.1.1

- Anchor the Blizzard quest dialog in the upper-right area for accepting quests, checking progress, and claiming rewards.

## 1.1.0

- Refresh the setup window with a Warcraft-style frame, brown buttons and a title below the metal trim.
- Frame the minimap in metal and give the zone label and footer translucent black backgrounds. Keep native tracking and calendar controls.
- Keep the 1.0.7 fonts and shadows for unit frames and the raid preview. Use flat textures for health, power, cast, reputation and experience bars.
- Use themed unit and aura tooltips outside combat, with Blizzard tooltips available as a fallback.
- Support a locally supplied Expressway font for themed text, with the client font as a fallback.

## 1.0.7

- Update class resource bar geometry only when the segment count changes.
- Read the game clock once per tick, including at minute changes.
- Streamline local checks and make release ZIPs reproducible.

## 1.0.6

- Added German and English localization, with English as the fallback.
- Existing `ScreenshotUIDB` settings migrate when the new `AzerothBuddyUI` database is absent.
- Setup confirmation remains per character.

## 1.0.5

- CurseForge-Projekt-ID und Paketkonfiguration ergänzt.

## 1.0.4

- Autorenangabe in der Addonübersicht auf **norushflow** geändert.

## 1.0.3

- Setupfenster zeigt die vorgesehene Layout-Auflösung von 3440 × 1440 Pixeln an.
- Setupfenster erscheint auf jedem neuen Charakter und nach jedem Versionsupdate erneut und lässt sich über `/abui on` öffnen.
- „One Button Setup“ warnt vor dem Überschreiben und ersetzt das Layout **AzerothBuddyUI** durch die mitgelieferte Vorlage.
- Geschützten Reload aus der verzögerten Setupprüfung entfernt; nach erfolgreicher Einrichtung wird zum manuellen `/reload` aufgefordert.
- Tatsächliche Layoutauswahl wird bestätigt; Kampf und fehlgeschlagene Auswahl werden abgefangen.
- Icon in der Addonübersicht im spielgeeigneten TGA-Format ergänzt.

## 1.0.2

- Retail-Layoutimport und lesende Layoutstatusanzeige hinzugefügt.
- Layout wird nach Verlassen des Bearbeitungsmodus verzögert wieder angeordnet.

## 1.0.1

- Formen-, Haltungs- und Begleiterbuttons übernehmen Größe und Skalierung von Aktionsleiste 4.
- Gesamtbreite und Größenänderungen folgen den nativen Buttons bei unverändertem Abstand.
