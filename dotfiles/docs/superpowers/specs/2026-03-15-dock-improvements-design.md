# Dock Improvements Design
**Date**: 2026-03-15
**Scope**: Quickshell Dock in `flakes/Quickpanel/`

## Problem Statement

1. Icons zeigen `?` statt App-Icons (kein Icon-Theme installiert)
2. Hover-Tooltip zeigt abgeschnittene Tab-Namen
3. Klick auf Dock-Item soll das offene Fenster fokussieren (bereits implementiert — muss bei Umstrukturierung erhalten bleiben)
4. Gepinnte Apps (Ghostty, Zen Browser, Vesktop, Spotify, Steam) fehlen
5. App-Menu-Button (9-Punkte-SVG) zum Öffnen/Schließen von wofi fehlt

## Lösung: Ansatz A — Alles in QML, Papirus-Theme via Nix

---

### 1. Icon-Theme (Nix)

**Datei**: `home/luna/modules/default-hyprland/theme.nix`

```nix
gtk.iconTheme = {
  name = "Papirus-Dark";
  package = pkgs.papirus-icon-theme;
};

qt = {
  enable = true;
  platformTheme.name = "gtk3";
  # qt6gtk2 lässt Qt QIcon::fromTheme das GTK Icon-Theme lesen
  style = {
    name = "adwaita-dark";
    package = pkgs.adwaita-qt;
  };
};
```

`home.packages` muss `pkgs.qt6Packages.qt6gtk2` (oder `pkgs.libsForQt5.qt5.qtstyleplugins`) enthalten.

**Warum Qt-Plattform-Theme erforderlich ist**: Quickshell ist eine Qt-Anwendung. `image://theme/<name>` verwendet intern `QIcon::fromTheme`. Qt liest den Icon-Theme-Namen nur aus GSettings/dconf, wenn der Qt-Platform-Theme auf `gtk3` gesetzt ist. Ohne das wird Papirus zwar installiert, aber Qt findet es nicht. `XDG_DATA_DIRS` allein reicht nicht.

---

### 2. Gepinnte Apps

**Neue Datei**: `flakes/Quickpanel/qml/PinnedItem.qml`

Ähnlich wie `DockItem.qml`, aber:
- Kein Workspace-Badge
- Icon-Source: `"image://theme/" + pinnedApp.class` (gleiche Lowercase-Retry-Logik wie `DockItem`, inklusive `property bool retried: false` Guard gegen infinite Loop)
- Erkennt ob App läuft: sucht in `Hyprland.toplevels.values` nach einem Eintrag dessen `lastIpcObject.class` (case-insensitive) mit `pinnedApp.class` übereinstimmt
- Klick:
  - App läuft → `Hyprland.dispatch("focuswindow class:" + pinnedApp.class)`
  - App läuft nicht → `Hyprland.dispatch("exec " + pinnedApp.exec)`
- Hover-Glow, Spring-Magnification, Tooltip mit `pinnedApp.name` — identisch zu `DockItem`

**In `Dock.qml`** statische Liste:

```qml
readonly property var pinnedApps: [
    { name: "Ghostty",     class: "com.mitchellh.ghostty", exec: "ghostty" },
    { name: "Zen Browser", class: "zen",                   exec: "zen" },
    { name: "Vesktop",     class: "vesktop",               exec: "vesktop" },
    { name: "Spotify",     class: "spotify",               exec: "spotify" },
    { name: "Steam",       class: "steam",                 exec: "steam" },
]
```

**`openWindowCount`** — neue Property in `Dock.qml`:
```qml
readonly property int openWindowCount: {
    var count = 0
    var tls = Hyprland.toplevels.values
    for (var i = 0; i < tls.length; i++)
        if (!tls[i].lastIpcObject.floating) count++
    return count
}
```

**Icon-Row Layout** (links → rechts):
1. Gepinnte Apps (`PinnedItem` × 5)
2. Trennlinie — `visible: openWindowCount > 0` (nur sichtbar wenn nicht-floating Fenster vorhanden)
3. Offene Fenster (`DockItem` Repeater) — **bestehende Filterlogik muss erhalten bleiben**
4. App-Menu-Button (`AppMenuButton`) — ganz rechts

**Wichtig**: Die bestehende `emptyWorkspace`-Logik (`refreshEmpty()`, `Connections`-Blöcke, `dockRoot.y`/`opacity`-Animations) in `Dock.qml` **darf nicht verändert werden**. Die Icon-Row-Umstrukturierung betrifft nur den Inhalt von `iconRow` innerhalb von `pill`.

---

### 3. Tooltip-Fix

**Problem**: Der Tooltip in `DockItem` hat eine negative `y`-Position (sitzt über dem Icon). Er wird vom `PanelWindow`'s `implicitHeight` abgeschnitten, weil Quickshell/wlr-layer-shell die Window-Höhe auf den deklarierten Wert begrenzt.

**Fix in `Dock.qml`** — nur `implicitHeight` ändern, `dockRoot.y`-Logik unverändert lassen:

```qml
// Tooltip-Überhang über dem Dock berücksichtigen (ca. 40px für Label + Abstand)
readonly property int tooltipOverhead: 44

// Vorher: dockHeight + dockMarginB + 16
implicitHeight: dockHeight + dockMarginB + 16 + tooltipOverhead
```

Die bestehende `y`-Berechnung in `dockRoot` bleibt unverändert:
```qml
y: root.emptyWorkspace ? 0 : (root.dockHeight + root.dockMarginB + 32)
```
Das `tooltipOverhead` gibt zusätzlichen vertikalen Raum oben im Fenster — der Tooltip kann nun über den Dock-Pill hinaus rendern ohne abgeschnitten zu werden.

Zusätzlich: `z: 100` auf den Tooltip-`Rectangle` in `DockItem.qml` setzen (wirkt innerhalb des `DockItem`-Stacking).

---

### 4. App-Menu-Button

**Neue Datei**: `flakes/Quickpanel/qml/AppMenuButton.qml`

**SVG-Asset**: `appmenu.svg` liegt unter `home/luna/modules/default-hyprland/icons/appmenu.svg`. Da das Quickshell-Paket nur `qml/` kopiert (`src = ./qml` in `flake.nix`), muss die SVG in `flakes/Quickpanel/qml/icons/appmenu.svg` kopiert werden. Im QML: `source: Qt.resolvedUrl("icons/appmenu.svg")`.

**Logik**:
```qml
property bool wofiOpen: false

Process {
    id: wofiProc
    command: ["wofi", "--show", "drun"]
    onExited: wofiOpen = false   // State korrekt wenn User Escape drückt
}

// Klick-Handler:
if (wofiOpen) {
    wofiProc.running = false  // sendet SIGTERM an wofi
    wofiOpen = false
} else {
    wofiProc.running = true
    wofiOpen = true
}
```

Ein einziges `Process`-Objekt namens `wofiProc` — konsistent in Deklaration und Click-Handler.

- Hover-Glow (lila Border wie `DockItem`)
- Feste Größe 52×52px, kein Badge, kein Workspace-Tracking

---

### 5. `cGreen`-Bug in `Dock.qml` (pre-existing)

`Dock.qml` Zeile 37: `readonly property color cGreen: "#a855f7"` ist tatsächlich lila. `DockItem.qml` referenziert `cGreen` nicht, aber `PinnedItem.qml` sollte für den Aktiv-Indikator-Punkt `panel.cAccent` (#a855f7) direkt verwenden — nicht `panel.cGreen`.

---

## Dateien die geändert/erstellt werden

| Datei | Änderung |
|-------|----------|
| `home/luna/modules/default-hyprland/theme.nix` | Papirus Icon-Theme + `qt.platformTheme.name = "gtk3"` |
| `home/luna/home.nix` oder Theme-Modul | `pkgs.qt6Packages.qt6gtk2` zu `home.packages` hinzufügen |
| `flakes/Quickpanel/qml/Dock.qml` | `pinnedApps` Liste, Icon-Row neu strukturieren, `tooltipOverhead` in `implicitHeight`, `PinnedItem` + Trennlinie + `AppMenuButton` einbinden |
| `flakes/Quickpanel/qml/DockItem.qml` | Tooltip `z: 100` |
| `flakes/Quickpanel/qml/PinnedItem.qml` | **Neue Datei** |
| `flakes/Quickpanel/qml/AppMenuButton.qml` | **Neue Datei** |
| `flakes/Quickpanel/qml/icons/appmenu.svg` | **Kopie** von `home/luna/modules/default-hyprland/icons/appmenu.svg` |
| `flakes/Quickpanel/flake.nix` | `dockFiles` Liste um `PinnedItem.qml`, `AppMenuButton.qml` erweitern; `xdg.configFile` um separaten Eintrag für `icons/`-Verzeichnis ergänzen (s.u.) |

### 6. `flake.nix` — `icons/`-Verzeichnis in `xdg.configFile`

`builtins.readDir` in `flake.nix` liest nur flache Einträge — `icons/` erscheint als Typ `"directory"`, kein regulärer File. Der bestehende `mapAttrs'`-Loop kann Verzeichnisse nicht korrekt mappen.

**Fix**: Den `mapAttrs'`-Loop auf reguläre Dateien beschränken (`type == "regular"`) und das `icons/`-Verzeichnis separat mit `recursive = true` eintragen:

```nix
xdg.configFile =
  let
    allFiles  = builtins.readDir qmlSrc;
    dockFiles = [ "Dock.qml" "DockItem.qml" "PinnedItem.qml" "AppMenuButton.qml" ];
    filtered  = if cfg.dock.enable
                then lib.filterAttrs (_: t: t == "regular") allFiles
                else lib.filterAttrs (n: t: t == "regular" && !(builtins.elem n dockFiles)) allFiles;
    fileMappings = lib.mapAttrs' (name: _:
      lib.nameValuePair ("quickshell/" + name) { source = "${qmlSrc}/${name}"; }
    ) filtered;
    iconMapping = lib.optionalAttrs cfg.dock.enable {
      "quickshell/icons" = { source = "${qmlSrc}/icons"; recursive = true; };
    };
  in fileMappings // iconMapping;
```

---

## Nicht im Scope

- Eigener Quickshell-App-Launcher (kommt später)
- Persistenz der gepinnten Apps (statische Liste reicht)
- Dock auf nicht-leeren Workspaces
