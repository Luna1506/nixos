# Quickpanel Redesign — "Neon Grid"

**Date:** 2026-03-15
**Status:** Approved

## Kontext

Das bestehende Quickpanel (Quickshell/QML, Hyprland) hat folgende Probleme:
- Glasmorphismus-Look wirkt langweilig
- Icons überlappen sich
- Buttons funktionieren nur halb (zu klein, schlechte Klickflächen)
- Panel insgesamt zu klein (360px breit)

## Ziel

Komplettes visuelles Redesign im Cyber/Synthwave-Stil: Neon-Farben auf tiefem Dunkel, keine Glaseffekte, deutlich größer, alle Icons in Badges eingebettet (kein Overlap), Buttons deutlich größer.

## Farbpalette

| Property     | Hex       | Verwendung                              |
|--------------|-----------|-----------------------------------------|
| `cBase`      | `#0a0a12` | Panel-Hintergrund                       |
| `cCard`      | `#11111f` | Karten-Hintergrund                      |
| `cBorder`    | `#1e1e3a` | Karten-Rahmen                           |
| `cText`      | `#e8e8ff` | Primärtext                              |
| `cSubtext`   | `#7070a0` | Labels, sekundärer Text                 |
| `cNeonCyan`  | `#00f5ff` | WLAN, Uhr, Play-Button, Slider          |
| `cNeonPink`  | `#ff2d78` | Bluetooth, Stop-Button, Fehler/Kritis   |
| `cNeonViolet`| `#bf00ff` | Batterie, Tab-Indicator, Album-Art-Icon |
| `cNeonYellow`| `#ffe600` | Batterie-Warnung (15–40%)               |

## Panel-Struktur

- **Breite:** 560px
- **Höhe:** dynamisch (Inhalt + 28px Padding oben/unten je 14px)
- **Position:** top-right, `margins.top: 52`, `margins.right: 14`
- **Hintergrund:** `cBase`, opak — kein Glasmorphismus
- **Rahmen:** 1px, `cBorder`, `radius: 16`

### Tab-Bar

Die `TabBar`-Komponente wird durch eine eigene Pill-Toggle-Bar ersetzt:
- Zwei `Text`-Buttons nebeneinander in einem `Rectangle`
- Aktiver Tab: 3px Neon-Unterstrich (`cNeonCyan`), animiert als `Rectangle` dessen `x`-Position mit `NumberAnimation { duration: 200; easing.type: Easing.OutCubic }` verschoben wird
- Inaktiver Tab: `cSubtext`, kein Hintergrund

> **Hinweis:** `margins.right` wird von `12` auf `14` geändert (bewusste Anpassung).

## StatusTab

### Uhr-Karte
- `implicitHeight: 100`
- Uhrzeit: `font.pixelSize: 48`, `Font.Light`, `cNeonCyan`
- Glow-Effekt: **immer den Fallback verwenden** — doppelter `Text` mit identischem Inhalt, `opacity: 0.30`, `font.pixelSize: 52` (etwas größer für Blur-Illusion), dahinter positioniert. `MultiEffect` ist in dieser Quickshell-Umgebung nicht zuverlässig verfügbar (Qt-Version-abhängig) und soll nicht verwendet werden.
- Datum: `font.pixelSize: 14`, `cSubtext`, zentriert darunter

### Icon-Badge-System
Alle Status-Rows bekommen links eine Badge:
- Größe: `32×32px`, `radius: 8`
- Hintergrund: Neon-Farbe bei 15% Opacity (`Qt.rgba(r, g, b, 0.15)`)
- Icon darin: `font.pixelSize: 20`, volle Neon-Farbe

### WiFi-Karte
- `implicitHeight: 68`
- Badge: `cNeonCyan` (15%)
- Icon: `""` / `""`, Farbe `cNeonCyan` (verbunden) oder `cNeonPink` (getrennt)
- Label "WiFi": `cSubtext`, `13px`
- SSID rechts: `cText`, `15px`

### Bluetooth-Karte
- `implicitHeight: 68`
- Badge: `cNeonPink` (15%)
- Icon: `""`, Farbe `cNeonPink` (an) / `cSubtext` (aus)
- Status + Gerätename rechts: `cText`, `15px`

### Batterie-Karte
- `implicitHeight: 84`
- Badge: `cNeonViolet` (15%)
- Icon dynamisch nach Status/Prozent, Farbe dynamisch
- Ladebalken: `height: 6`, `radius: 3`
  - Laden → `cNeonCyan`
  - >40% (d.h. pct >= 41) → `cNeonViolet`
  - >15% (d.h. pct >= 16) → `cNeonYellow`
  - ≤15% (d.h. pct <= 15) → `cNeonPink`

### StatusRow.qml — Änderungen
- Bestehende Properties bleiben erhalten: `required property string icon` (Icon-Glyph), `required property color iconColor`, `required property string label`, `required property string value`
- Neue optionale Property: `property color badgeColor` (Standardwert: `"transparent"`) — wenn gesetzt (nicht transparent), wird das Icon in eine Badge eingebettet
- `implicitHeight: 68` statt 44
- Linker Bereich: Badge-`Rectangle` (32×32, `radius: 8`, Hintergrund `Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.15)`) mit dem Icon-`Text` darin
- Rechts: Label + Value wie bisher

## PlayerTab

### Track-Info-Karte
- `implicitHeight: 96`
- Album-Art-Platzhalter: `72×72px`, `radius: 10`, `cCard`, `border.color: cBorder`
- Icon darin: `28px`, `cNeonViolet`
- Titel: `16px`, `Font.SemiBold`, `cText`
- Artist: `13px`, `cNeonCyan`
- Album: `11px`, `cSubtext`

### Controls-Karte
- `implicitHeight: 68`
- Buttons: `48×48px` statt 40×40px
- Play/Pause: Hintergrund `cNeonCyan`, Icon `cBase`, `iconSize: 26`
- Previous/Next: transparent, hover → `cBorder`, Icon `cText`, `iconSize: 20`
- Stop: transparent, hover → `cBorder`, Icon `cNeonPink`, `iconSize: 20`

### CtrlButton.qml — Änderungen
- Property `iconText` → `icon` umbenennen: sowohl die `required property string iconText`-Deklaration als auch die interne Verwendung `text: iconText` im `contentItem` müssen auf `icon` geändert werden
- `implicitWidth/Height: 48` statt 40
- Hover-Farbe: `cBorder` statt `cOverlay`

**Alle Aufrufstellen in `PlayerTab.qml` müssen ebenfalls aktualisiert werden** (4 Stellen):
- Zeile ~195: `iconText: ""` → `icon: ""`
- Zeile ~202: `iconText: root.isPlaying ? "" : ""` → `icon: root.isPlaying ? "" : ""`
- Zeile ~211: `iconText: ""` → `icon: ""`
- Zeile ~225: `iconText: ""` → `icon: ""`

### Volume-Karte
- `implicitHeight: 64`
- Slider-Track: `height: 6`, Füllfarbe `cNeonCyan`
- Handle: `16×16px`, `cNeonCyan`
- Lautstärke-Prozent rechts: `cNeonCyan`

## Dateien die geändert werden

| Datei | Art der Änderung |
|---|---|
| `QuickPanel.qml` | Farbpalette, Größe (560px), Tab-Bar ersetzen |
| `StatusTab.qml` | Badge-System einbauen, Abstände anpassen |
| `StatusRow.qml` | `badgeColor` Property, `implicitHeight: 68` |
| `BatteryRow.qml` | Badge, Balken-Höhe 6px, neue Farben |
| `PlayerTab.qml` | Track-Info, Controls, Volume anpassen |
| `CtrlButton.qml` | `icon` umbenennen, Größe 48px, Hover-Farbe |

## Nicht geändert

- `Dock.qml` / `DockItem.qml` — kein Redesign angefragt
- `shell.qml` — keine Änderung nötig
- `flake.nix` — keine Änderung nötig
- Datenquellen / Prozesse — nur visuelles Redesign
