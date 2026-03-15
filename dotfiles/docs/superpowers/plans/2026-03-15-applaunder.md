# AppLauncher Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Quickshell app launcher that replaces wofi — a centered floating panel with search field and scrollable 3-column icon grid, matching the QuickPanel purple theme.

**Architecture:** A `PanelWindow` (`AppLauncher.qml`) holds a search `TextInput` and a `GridView` backed by a filtered model over `DesktopEntries.applications`. Each grid cell is `AppLauncherItem.qml`. The launcher is toggled via QS IPC (`applaunch toggle`) from both `SUPER+R` and the dock's `AppMenuButton`. `DesktopEntry.execute()` launches apps.

**Tech Stack:** Nix/Home Manager, Quickshell ≥ 0.2 (QML/Qt6), `Quickshell.DesktopEntries`, `Quickshell.Wayland` (layer-shell), `Quickshell.Io` (IPC)

---

## Chunk 1: AppLauncherItem.qml

### Task 1: Create AppLauncherItem.qml

**Files:**
- Create: `flakes/Quickpanel/qml/AppLauncherItem.qml`

**Context:** Single cell in the app grid. Shows icon (52px, via `Quickshell.iconPath(entry.icon)`), app name below (truncated). Hover: purple glow border + slight scale-up (same spring animation as DockItem/PinnedItem). Click emits `launched` signal so the parent can close the launcher.

- [ ] **Step 1: Create AppLauncherItem.qml**

Create `/home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppLauncherItem.qml`:

```qml
// ─── AppLauncherItem.qml ──────────────────────────────────────────────────────
// Single app cell in the AppLauncher grid.

import Quickshell
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var entry    // DesktopEntry
    signal launched()

    implicitWidth:  120
    implicitHeight: 110

    property bool hovered: false

    // ── Icon rectangle ────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width:  52
        height: 52
        radius: 52 * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              parent.top
            topMargin:        12
        }

        color:        iconImg.status === Image.Ready ? "transparent" : root.fallbackColor()
        border.color: root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.60) : "transparent"
        border.width: 1

        scale: root.hovered ? 1.12 : 1.0
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Image {
            id: iconImg
            anchors.fill:    parent
            anchors.margins: 4
            source:          Quickshell.iconPath(root.entry.icon || "", "")
            fillMode:        Image.PreserveAspectFit
            smooth:          true
            mipmap:          true
            visible:         status === Image.Ready
        }

        // Letter fallback
        Text {
            anchors.centerIn: parent
            visible:          iconImg.status !== Image.Ready
            text:             (root.entry.name || "?").charAt(0).toUpperCase()
            font.pixelSize:   22
            font.weight:      Font.Bold
            color:            "#ffffff"
        }
    }

    // ── App name ──────────────────────────────────────────────────────────────
    Text {
        anchors {
            top:              iconRect.bottom
            topMargin:        6
            horizontalCenter: parent.horizontalCenter
            left:             parent.left
            right:            parent.right
            leftMargin:       4
            rightMargin:      4
        }
        text:            root.entry.name || ""
        color:           root.hovered ? "#D19CFF" : "#8a6aaa"
        font.pixelSize:  11
        font.weight:     Font.Medium
        horizontalAlignment: Text.AlignHCenter
        elide:           Text.ElideRight
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // ── Hover background ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill:    parent
        anchors.margins: 4
        radius:          10
        color:           root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        z:               -1
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered:    root.hovered = true
        onExited:     root.hovered = false
        onClicked: {
            root.entry.execute()
            root.launched()
        }
    }

    // ── Deterministic fallback colour from name ───────────────────────────────
    function fallbackColor() {
        var s    = root.entry.name || "?"
        var hash = 0
        for (var i = 0; i < s.length; i++)
            hash = (hash * 31 + s.charCodeAt(i)) & 0xFFFFFF
        var h = (hash & 0xFF) / 255
        var sat = 0.50 + ((hash >> 8 & 0xFF) / 255) * 0.35
        var v   = 0.52 + ((hash >> 16 & 0xFF) / 255) * 0.22
        return Qt.hsva(h, sat, v, 1)
    }
}
```

- [ ] **Step 2: Verify file exists**

```bash
ls -la /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppLauncherItem.qml
```

Expected: file exists, non-zero size.

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add flakes/Quickpanel/qml/AppLauncherItem.qml
git commit -m "feat: add AppLauncherItem grid cell component"
```

---

## Chunk 2: AppLauncher.qml

### Task 2: Create AppLauncher.qml

**Files:**
- Create: `flakes/Quickpanel/qml/AppLauncher.qml`

**Context:** `PanelWindow` centered on screen. Layer: `WlrLayer.Overlay`, keyboard focus `OnDemand`. Size: 420×580px. Background matches QuickPanel exactly (dark base, radial glows via Canvas, purple border). Contains a search `TextInput` (auto-focused on show) and a `GridView` with 3 columns filtered by search text against `entry.name` and `entry.keywords`. Only entries where `noDisplay !== true` are shown. `Escape` and click-outside close the launcher.

- [ ] **Step 1: Create AppLauncher.qml**

Create `/home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppLauncher.qml`:

```qml
// ─── AppLauncher.qml ──────────────────────────────────────────────────────────
// Centered floating app launcher with search + 3-column icon grid.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root

    // ── IPC toggle ────────────────────────────────────────────────────────────
    IpcHandler {
        target: "applaunch"
        function toggle(): void {
            root.visible = !root.visible
            if (root.visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        function show(): void {
            root.visible = true
            searchField.text = ""
            searchField.forceActiveFocus()
        }
        function hide(): void { root.visible = false }
    }

    // ── Colours (matches QuickPanel) ──────────────────────────────────────────
    readonly property color cBase:    "#0d0d1a"
    readonly property color cText:    "#D19CFF"
    readonly property color cSubtext: "#8a6aaa"
    readonly property color cAccent:  "#a855f7"

    // ── Layer-shell ───────────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Center on screen
    anchors.left:   false
    anchors.right:  false
    anchors.top:    false
    anchors.bottom: false

    implicitWidth:  420
    implicitHeight: 580

    color:   "transparent"
    visible: false

    Keys.onEscapePressed: root.visible = false

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        root.cBase
        radius:       16
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var g1 = ctx.createRadialGradient(
                width * 0.05, height * 0.05, 0,
                width * 0.05, height * 0.05, width * 0.75
            )
            g1.addColorStop(0,   Qt.rgba(0.627, 0.082, 0.996, 0.30))
            g1.addColorStop(1.0, Qt.rgba(0, 0, 0, 0))
            ctx.fillStyle = g1
            ctx.fillRect(0, 0, width, height)

            var g2 = ctx.createRadialGradient(
                width * 0.95, height * 0.90, 0,
                width * 0.95, height * 0.90, width * 0.65
            )
            g2.addColorStop(0,   Qt.rgba(0.933, 0.286, 0.600, 0.22))
            g2.addColorStop(1.0, Qt.rgba(0, 0, 0, 0))
            ctx.fillStyle = g2
            ctx.fillRect(0, 0, width, height)
        }
    }

    Rectangle {
        anchors.fill:  parent
        color:         "transparent"
        radius:        16
        border.color:  "#A015FE"
        border.width:  1
    }

    // ── Filtered model ────────────────────────────────────────────────────────
    property string searchText: ""

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors {
            fill:         parent
            margins:      14
        }
        spacing: 10

        // ── Search bar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   40
            radius:           10
            color:            Qt.rgba(0.05, 0.04, 0.10, 0.80)
            border.color:     searchField.activeFocus
                              ? Qt.rgba(0.627, 0.082, 0.996, 0.80)
                              : Qt.rgba(0.627, 0.082, 0.996, 0.30)
            border.width:     1
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Row {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:           parent.left
                    leftMargin:     10
                    right:          parent.right
                    rightMargin:    10
                }
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:       "🔍"
                    font.pixelSize: 14
                    color:      root.cSubtext
                }

                TextInput {
                    id:                 searchField
                    width:              parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    color:              root.cText
                    font.pixelSize:     14
                    font.weight:        Font.Medium
                    placeholderText:    "App suchen…"
                    placeholderTextColor: root.cSubtext
                    selectByMouse:      true
                    clip:               true
                    onTextChanged:      root.searchText = text.toLowerCase()
                }
            }
        }

        // ── App grid ──────────────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy:   ScrollBar.AsNeeded

            GridView {
                id:          grid
                width:       parent.width
                cellWidth:   Math.floor(width / 3)
                cellHeight:  110
                clip:        true

                model: DesktopEntries.applications

                delegate: AppLauncherItem {
                    required property var modelData

                    width:  grid.cellWidth
                    height: grid.cellHeight

                    entry: modelData

                    visible: {
                        if (modelData.noDisplay) return false
                        if (root.searchText === "") return true
                        var n = (modelData.name || "").toLowerCase()
                        var k = (modelData.keywords || "").toLowerCase()
                        return n.includes(root.searchText) || k.includes(root.searchText)
                    }

                    onLaunched: root.visible = false
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify file exists**

```bash
ls -la /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppLauncher.qml
```

Expected: file exists, non-zero size.

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add flakes/Quickpanel/qml/AppLauncher.qml
git commit -m "feat: add AppLauncher panel with search and 3-column grid"
```

---

## Chunk 3: Integration — shell.qml, AppMenuButton.qml, binds.nix, flake.nix

### Task 3: Wire AppLauncher into shell.qml

**Files:**
- Modify: `flakes/Quickpanel/qml/shell.qml`

**Context:** `AppLauncher` muss als Root-Child in `ShellRoot` registriert werden, damit der IpcHandler aktiv ist. Einfach `AppLauncher { id: launcher }` hinzufügen.

- [ ] **Step 1: Add AppLauncher to shell.qml**

In `flakes/Quickpanel/qml/shell.qml` nach `Dock {}` einfügen:

```qml
    // ── App Launcher (SUPER+R / Dock-Button) ──────────────────────────────────
    AppLauncher {}
```

- [ ] **Step 2: Verify**

```bash
grep "AppLauncher" /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/shell.qml
```

Expected: `AppLauncher {}` gefunden.

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add flakes/Quickpanel/qml/shell.qml
git commit -m "feat: register AppLauncher in ShellRoot"
```

---

### Task 4: Update AppMenuButton to use IPC instead of wofi

**Files:**
- Modify: `flakes/Quickpanel/qml/AppMenuButton.qml`

**Context:** Statt `Process { command: ["wofi", ...] }` nutzen wir `Quickshell.execDetached(["qs", "ipc", "call", "applaunch", "toggle"])`. Kein Process-Objekt mehr nötig — einfacher und zuverlässiger.

- [ ] **Step 1: Replace wofi process with IPC call in AppMenuButton.qml**

Ersetze den gesamten Inhalt von `AppMenuButton.qml`:

```qml
// ─── AppMenuButton.qml ────────────────────────────────────────────────────────
// 9-dot grid button that toggles the AppLauncher via QS IPC.

import Quickshell
import QtQuick

Item {
    id: root

    required property var panel  // Dock root (colours + size constants)

    implicitWidth:  panel.iconBase + 4
    implicitHeight: panel.dockHeight

    property bool hovered: false

    // ── Icon ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: btnRect
        width:  panel.iconBase
        height: panel.iconBase
        radius: panel.iconBase * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
            verticalCenterOffset: -5
        }

        color:        Qt.rgba(0.05, 0.04, 0.10, 0.60)
        border.color: root.hovered
            ? Qt.rgba(0.627, 0.082, 0.996, 0.60)
            : Qt.rgba(0.627, 0.082, 0.996, 0.20)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 100 } }

        scale: root.hovered ? (panel.iconHover / panel.iconBase) : 1.0
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }

        Image {
            anchors.centerIn: parent
            width:  parent.width  * 0.58
            height: parent.height * 0.58
            source: Qt.resolvedUrl("icons/appmenu.svg")
            fillMode: Image.PreserveAspectFit
            smooth:   true
            mipmap:   true
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "applaunch", "toggle"])
    }
}
```

- [ ] **Step 2: Verify**

```bash
grep -c "wofi\|Process" /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppMenuButton.qml
```

Expected: `0`

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add flakes/Quickpanel/qml/AppMenuButton.qml
git commit -m "feat: replace wofi in AppMenuButton with AppLauncher IPC call"
```

---

### Task 5: Update binds.nix — SUPER+R → AppLauncher

**Files:**
- Modify: `home/luna/modules/default-hyprland/binds.nix`

**Context:** `$mainMod, R` zeigt aktuell auf `$menu` (wofi). Ersetzen durch QS-IPC-Call.

- [ ] **Step 1: Replace SUPER+R binding**

In `home/luna/modules/default-hyprland/binds.nix` die Zeile:

```nix
"$mainMod, R, exec, $menu"
```

ersetzen durch:

```nix
"$mainMod, R, exec, qs ipc call applaunch toggle"
```

- [ ] **Step 2: Verify Nix syntax**

```bash
nix-instantiate --parse /home/luna/nixos/dotfiles/home/luna/modules/default-hyprland/binds.nix && echo "OK"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add home/luna/modules/default-hyprland/binds.nix
git commit -m "feat: bind SUPER+R to AppLauncher IPC toggle"
```

---

### Task 6: Update flake.nix — new files in dockFiles list

**Files:**
- Modify: `flakes/Quickpanel/flake.nix`

**Context:** `AppLauncher.qml` und `AppLauncherItem.qml` müssen in `dockFiles` aufgenommen werden, damit sie bei `dock.enable = false` ausgeschlossen werden (da sie vom Dock-Button abhängen).

- [ ] **Step 1: Add new files to dockFiles in flake.nix**

In `flakes/Quickpanel/flake.nix` die Zeile:

```nix
dockFiles = [ "Dock.qml" "DockItem.qml" "PinnedItem.qml" "AppMenuButton.qml" ];
```

ersetzen durch:

```nix
dockFiles = [ "Dock.qml" "DockItem.qml" "PinnedItem.qml" "AppMenuButton.qml" "AppLauncher.qml" "AppLauncherItem.qml" ];
```

- [ ] **Step 2: Verify Nix syntax**

```bash
nix-instantiate --parse /home/luna/nixos/dotfiles/flakes/Quickpanel/flake.nix && echo "OK"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd /home/luna/nixos/dotfiles
git add flakes/Quickpanel/flake.nix
git commit -m "fix: add AppLauncher components to dockFiles exclusion list"
```

---

## Chunk 4: Rebuild & Verify

### Task 7: Rebuild NixOS and verify

- [ ] **Step 1: Rebuild**

```bash
cd /home/luna/nixos/dotfiles
sudo nixos-rebuild switch --flake .#laptop
```

Expected: Build erfolgreich, keine Fehler.

- [ ] **Step 2: Restart Quickshell**

```bash
systemctl --user restart quickshell
```

- [ ] **Step 3: Verify SUPER+R öffnet den Launcher**

Drücke `SUPER+R`. Expected: AppLauncher erscheint zentriert. Suchfeld ist fokussiert.

- [ ] **Step 4: Verify Suche filtert Apps**

Tippe „fire". Expected: Nur Firefox (oder ähnliche Apps) werden angezeigt.

- [ ] **Step 5: Verify App starten**

Klicke eine App. Expected: App startet, Launcher schließt sich.

- [ ] **Step 6: Verify Escape schließt**

Öffne Launcher, drücke Escape. Expected: Launcher verschwindet.

- [ ] **Step 7: Verify Dock-Button öffnet Launcher**

Klicke den 9-Dot-Button im Dock. Expected: Launcher öffnet sich.

- [ ] **Step 8: Check Quickshell logs für Fehler**

```bash
journalctl --user -u quickshell -n 30 --no-pager | grep -i "error\|warn" | grep -v "dbus\|PlayerTab\|anchors\|Keys"
```

Expected: Keine neuen Fehler.
