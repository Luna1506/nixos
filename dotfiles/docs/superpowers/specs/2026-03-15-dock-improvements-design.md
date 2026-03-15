# Dock Improvements Design
**Date**: 2026-03-15
**Scope**: Quickshell Dock in `flakes/Quickpanel/`

## Problem Statement

1. Icons zeigen `?` statt App-Icons (kein Icon-Theme installiert)
2. Hover-Tooltip zeigt abgeschnittene Tab-Namen
3. Klick auf Dock-Item soll das offene Fenster fokussieren (bereits implementiert, sicherstellen dass es korrekt funktioniert)
4. Gepinnte Apps (Ghostty, Zen Browser, Vesktop, Spotify, Steam) fehlen
5. App-Menu-Button (9-Punkte-SVG) zum Öffnen/Schließen von wofi fehlt

## Lösung: Ansatz A — Alles in QML, Papirus-Theme via Nix

### 1. Icon-Theme (Nix)

**Datei**: `home/luna/home.nix` oder passendes Modul

```nix
gtk.iconTheme = {
  name = "Papirus-Dark";
  package = pkgs.papirus-icon-theme;
};
```

`qt.platformTheme` auf `gtk` setzen oder `XDG_DATA_DIRS` via `home.sessionVariables` explizit setzen, damit Quickshell (Qt-App) den Papirus-Pfad findet.

**Warum**: Quickshell's `image://theme/<classname>` benötigt ein installiertes Icon-Theme. Papirus deckt alle gewünschten Apps ab (Ghostty, Zen, Vesktop, Spotify, Steam).

### 2. Gepinnte Apps

**Neue Datei**: `flakes/Quickpanel/qml/PinnedItem.qml`

Ähnlich wie `DockItem.qml`, aber:
- Kein Workspace-Badge
- Erkennt ob App läuft via Match auf `Hyprland.toplevels.values` nach `class`
- Klick: wenn App läuft → `focuswindow address:<addr>`, sonst → `exec <exec>`
- Hover-Glow, Spring-Magnification, Tooltip wie DockItem

**In `Dock.qml`** wird eine statische Liste definiert:

```qml
readonly property var pinnedApps: [
    { name: "Ghostty",     class: "com.mitchellh.ghostty", exec: "ghostty" },
    { name: "Zen Browser", class: "zen",                   exec: "zen" },
    { name: "Vesktop",     class: "vesktop",               exec: "vesktop" },
    { name: "Spotify",     class: "spotify",               exec: "spotify" },
    { name: "Steam",       class: "steam",                 exec: "steam" },
]
```

**Icon-Row Layout** (links → rechts):
1. Gepinnte Apps (`PinnedItem` × 5)
2. Trennlinie — nur sichtbar wenn offene Fenster vorhanden (`visible: Hyprland.toplevels.values.length > 0`)
3. Offene Fenster (`DockItem` Repeater)
4. App-Menu-Button (`AppMenuButton`)

### 3. Tooltip-Fix

**Problem**: Tooltip liegt außerhalb des `PanelWindow`-Clips.

**Fix in `DockItem.qml`**:
- `z: 100` auf den Tooltip-Rectangle setzen
- `clip: false` auf `dockRoot` Item sicherstellen

### 4. App-Menu-Button

**Neue Datei**: `flakes/Quickpanel/qml/AppMenuButton.qml`

- Zeigt `appmenu.svg` (bereits vorhanden unter `icons/appmenu.svg`)
- `property bool wofiOpen: false`
- Klick: `wofiOpen ? pkill wofi : wofi --show drun` via `Quickshell.Io.Process`
- Hover-Glow (lila Border, wie DockItem)
- Feste Größe 52×52px
- Ganz rechts im Icon-Row

## Dateien die geändert werden

| Datei | Änderung |
|-------|----------|
| `home/luna/home.nix` | Papirus Icon-Theme hinzufügen |
| `flakes/Quickpanel/qml/Dock.qml` | `pinnedApps` Liste, Icon-Row neu strukturieren, `PinnedItem` + `AppMenuButton` einbinden |
| `flakes/Quickpanel/qml/DockItem.qml` | Tooltip `z: 100` fix |
| `flakes/Quickpanel/qml/PinnedItem.qml` | **Neue Datei** |
| `flakes/Quickpanel/qml/AppMenuButton.qml` | **Neue Datei** |

## Nicht im Scope

- Eigener Quickshell-App-Launcher (kommt später)
- Persistenz der gepinnten Apps (statische Liste reicht)
- Dock auf nicht-leeren Workspaces
