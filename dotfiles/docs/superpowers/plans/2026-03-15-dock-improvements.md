# Dock Improvements Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix icons, tooltip clipping, add pinned apps and App-Menu-Button to the Quickshell dock.

**Architecture:** All changes stay within `flakes/Quickpanel/` (QML) and `home/luna/modules/default-hyprland/theme.nix` (Nix). No new dependencies beyond Papirus icon theme and qt6gtk2. New components (`PinnedItem.qml`, `AppMenuButton.qml`) follow the exact patterns of `DockItem.qml`.

**Tech Stack:** Nix/Home Manager, Quickshell ≥ 0.2 (QML/Qt6), Hyprland IPC (`Quickshell.Hyprland`), `Quickshell.Io.Process`

---

## Chunk 1: Nix — Icon-Theme & Qt-Platform-Theme

### Task 1: Papirus + qt6gtk2 in theme.nix

**Files:**
- Modify: `home/luna/modules/default-hyprland/theme.nix`

**Context:** `theme.nix` currently has `gtk.enable = true` with Adwaita-dark theme and `qt.enable = true` with `style.name = "adwaita-dark"`. No icon theme, no platform theme. Quickshell uses `image://theme/<classname>` which calls `QIcon::fromTheme` internally — this only works when Qt knows which GTK icon theme to use, which requires `qt.platformTheme.name = "gtk3"` and the `qt6gtk2` bridge package.

- [ ] **Step 1: Add icon theme and Qt platform theme**

Edit `home/luna/modules/default-hyprland/theme.nix`. The full new content:

```nix
{ pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.packages = [ pkgs.qt6Packages.qt6gtk2 ];

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
```

- [ ] **Step 2: Verify Nix syntax**

```bash
cd /home/luna/nixos/dotfiles
nix-instantiate --parse home/luna/modules/default-hyprland/theme.nix
```

Expected: no errors, outputs the parsed expression.

- [ ] **Step 3: Commit**

```bash
git add home/luna/modules/default-hyprland/theme.nix
git commit -m "feat: add Papirus icon theme and qt6gtk2 platform bridge"
```

---

## Chunk 2: QML — Tooltip-Fix & implicitHeight

### Task 2: Fix tooltip clipping in Dock.qml and DockItem.qml

**Files:**
- Modify: `flakes/Quickpanel/qml/Dock.qml:39-45,77`
- Modify: `flakes/Quickpanel/qml/DockItem.qml:42`

**Context:** The tooltip in `DockItem` is positioned at a negative `y` (above the icon). The `PanelWindow`'s `implicitHeight` constrains the layer-shell window height — anything rendered above the window boundary is clipped. Fix: add `tooltipOverhead: 44` to the constants and include it in `implicitHeight`. The `dockRoot.y` expression stays untouched.

- [ ] **Step 1: Add tooltipOverhead constant and update implicitHeight in Dock.qml**

In `flakes/Quickpanel/qml/Dock.qml`, in the sizing constants block (around line 39), add after `dockMarginB`:

```qml
    readonly property int tooltipOverhead: 44
```

Then change the `implicitHeight` line (currently line 77):

```qml
    // Before:
    implicitHeight: dockHeight + dockMarginB + 16
    // After:
    implicitHeight: dockHeight + dockMarginB + 16 + tooltipOverhead
```

- [ ] **Step 2: Add z:100 to tooltip Rectangle in DockItem.qml**

In `flakes/Quickpanel/qml/DockItem.qml`, on the `Rectangle { id: tooltip` block (around line 42), add `z: 100` as a property:

```qml
    Rectangle {
        id: tooltip
        z: 100
        visible: root.hovered && root.client.title.length > 0
```

- [ ] **Step 3: Verify QML syntax (quick check)**

```bash
grep -n "tooltipOverhead\|implicitHeight" /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/Dock.qml
grep -n "z: 100" /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/DockItem.qml
```

Expected: `tooltipOverhead` definition, updated `implicitHeight` line, and `z: 100` found.

- [ ] **Step 4: Commit**

```bash
git add flakes/Quickpanel/qml/Dock.qml flakes/Quickpanel/qml/DockItem.qml
git commit -m "fix: increase PanelWindow height to prevent tooltip clipping"
```

---

## Chunk 3: QML — PinnedItem.qml

### Task 3: Create PinnedItem.qml

**Files:**
- Create: `flakes/Quickpanel/qml/PinnedItem.qml`

**Context:** `PinnedItem` is a dock icon for a statically pinned app. Unlike `DockItem` it has no `HyprlandClient` — it gets a plain JS object `{ name, class, exec }`. It detects if the app is running by searching `Hyprland.toplevels.values`. Click behavior: focus if running, launch if not. Visual style is identical to `DockItem` (same magnification, hover glow, tooltip). No workspace badge.

- [ ] **Step 1: Create PinnedItem.qml**

Create `/home/luna/nixos/dotfiles/flakes/Quickpanel/qml/PinnedItem.qml`:

```qml
// ─── PinnedItem.qml ───────────────────────────────────────────────────────────
// Dock icon for a statically pinned application.
//
// Features
// ────────
//   • Icon from system icon theme  (image://theme/<class>)
//     Falls back to coloured circle with first letter.
//   • macOS-style spring magnification on hover.
//   • Tooltip: app name, shown above the icon.
//   • Active indicator dot when the app is running.
//   • Click → focus if running, launch if not.

import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland

Item {
    id: root

    // ── Required inputs ───────────────────────────────────────────────────────
    required property var  panel      // Dock root (colours + size constants)
    required property var  pinnedApp  // { name, class, exec }

    // ── Running state ─────────────────────────────────────────────────────────
    readonly property bool isRunning: {
        var tls = Hyprland.toplevels.values
        var cls = pinnedApp.class.toLowerCase()
        for (var i = 0; i < tls.length; i++) {
            var tc = (tls[i].lastIpcObject.class ?? "").toLowerCase()
            if (tc === cls) return true
        }
        return false
    }

    // ── Sizing ────────────────────────────────────────────────────────────────
    implicitWidth:  panel.iconHover + 4
    implicitHeight: panel.dockHeight

    // ── Hover ─────────────────────────────────────────────────────────────────
    property bool hovered: false

    readonly property real targetScale: hovered
        ? (panel.iconHover / panel.iconBase)
        : 1.0

    // ── Tooltip ───────────────────────────────────────────────────────────────
    Rectangle {
        id: tooltip
        z: 100
        visible: root.hovered
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        x: (parent.width - width) / 2

        property real scaledIconHalfH: (panel.iconBase / 2) * iconRect.scale
        property real iconCentreY:     parent.height / 2 - 5
        y: iconCentreY - scaledIconHalfH - height - 8

        implicitWidth:  Math.min(ttLabel.implicitWidth + 20, 210)
        implicitHeight: ttLabel.implicitHeight + 10
        radius:         8

        color:        Qt.rgba(0.10, 0.06, 0.18, 0.92)
        border.color: Qt.rgba(0.627, 0.082, 0.996, 0.35)
        border.width: 1

        Text {
            id: ttLabel
            anchors.centerIn: parent
            text:             root.pinnedApp.name
            color:            panel.cText
            font.pixelSize:   11
            font.weight:      Font.Medium
            elide:            Text.ElideRight
            width:            Math.min(implicitWidth, 190)
        }
    }

    // ── Icon rectangle ────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width:  panel.iconBase
        height: panel.iconBase
        radius: panel.iconBase * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
            verticalCenterOffset: -5
        }

        color:        iconFallback.visible ? root.iconColor() : "transparent"
        border.color: Qt.rgba(1, 1, 1, iconFallback.visible ? 0.08 : 0.0)
        border.width: 1

        scale: root.targetScale
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }

        SequentialAnimation {
            id: bounceAnim
            alwaysRunToEnd: true
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale * 0.80
                duration: 75; easing.type: Easing.InCubic
            }
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale * 1.10
                duration: 130; easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale
                duration: 200; easing.type: Easing.OutElastic
            }
        }

        // ── System icon ───────────────────────────────────────────────────────
        Image {
            id: iconImage
            anchors.fill:    parent
            anchors.margins: 4
            source:          "image://theme/" + (root.pinnedApp.class || "application-x-executable")
            fillMode:        Image.PreserveAspectFit
            smooth:          true
            mipmap:          true
            visible:         status === Image.Ready

            property bool retried: false
            onStatusChanged: {
                if (status === Image.Error && !retried) {
                    retried = true
                    source = "image://theme/" + root.pinnedApp.class.toLowerCase()
                }
            }
        }

        // ── Letter fallback ───────────────────────────────────────────────────
        Item {
            id: iconFallback
            anchors.fill: parent
            visible:      iconImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text:       (root.pinnedApp.class || "?").charAt(0).toUpperCase()
                font.pixelSize: parent.width * 0.42
                font.weight:    Font.Bold
                color:          "#ffffff"
            }
        }

        // ── Hover outline ─────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius:       parent.radius
            color:        "transparent"
            border.color: root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.60) : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }
    }

    // ── Active dot ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom:           parent.bottom
            bottomMargin:     8
        }
        width: 6; height: 6; radius: 3

        color:   root.isRunning ? panel.cAccent : Qt.rgba(0.659, 0.333, 0.969, 0.30)
        opacity: root.isRunning ? 1.0 : 0.40

        Behavior on color   { ColorAnimation  { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited:  root.hovered = false

        onClicked: {
            bounceAnim.restart()
            if (root.isRunning) {
                Hyprland.dispatch("focuswindow class:" + root.pinnedApp.class)
            } else {
                Hyprland.dispatch("exec " + root.pinnedApp.exec)
            }
        }
    }

    // ── Deterministic colour from class name ──────────────────────────────────
    function iconColor() {
        var cls  = root.pinnedApp.class || "?"
        var hash = 0
        for (var i = 0; i < cls.length; i++)
            hash = (hash * 31 + cls.charCodeAt(i)) & 0xFFFFFF

        var h = (hash        & 0xFF) / 255
        var s = 0.50 + ((hash >> 8  & 0xFF) / 255) * 0.35
        var v = 0.52 + ((hash >> 16 & 0xFF) / 255) * 0.22
        return Qt.hsva(h, s, v, 1)
    }
}
```

- [ ] **Step 2: Verify file exists**

```bash
ls -la /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/PinnedItem.qml
```

Expected: file exists, non-zero size.

- [ ] **Step 3: Commit**

```bash
git add flakes/Quickpanel/qml/PinnedItem.qml
git commit -m "feat: add PinnedItem component for statically pinned dock apps"
```

---

## Chunk 4: QML — AppMenuButton.qml + icons/

### Task 4: Copy appmenu.svg and create AppMenuButton.qml

**Files:**
- Create: `flakes/Quickpanel/qml/icons/appmenu.svg` (copy)
- Create: `flakes/Quickpanel/qml/AppMenuButton.qml`

**Context:** The SVG lives in `home/luna/modules/default-hyprland/icons/appmenu.svg`. The Quickshell package only bundles `qml/` so it must be copied there. `AppMenuButton` uses `Quickshell.Io.Process` to launch/kill wofi. A single `Process` object tracks the lifecycle; `onExited` resets `wofiOpen` so the toggle stays in sync if wofi is closed externally.

- [ ] **Step 1: Create icons directory and copy SVG**

```bash
mkdir -p /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/icons
cp /home/luna/nixos/dotfiles/home/luna/modules/default-hyprland/icons/appmenu.svg \
   /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/icons/appmenu.svg
```

- [ ] **Step 2: Verify copy**

```bash
ls /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/icons/
```

Expected: `appmenu.svg` listed.

- [ ] **Step 3: Create AppMenuButton.qml**

Create `/home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppMenuButton.qml`:

```qml
// ─── AppMenuButton.qml ────────────────────────────────────────────────────────
// 9-dot grid button that toggles wofi --show drun.

import QtQuick
import Quickshell.Io

Item {
    id: root

    required property var panel  // Dock root (colours + size constants)

    implicitWidth:  panel.iconBase + 4
    implicitHeight: panel.dockHeight

    property bool wofiOpen: false
    property bool hovered:  false

    // ── wofi process ──────────────────────────────────────────────────────────
    Process {
        id: wofiProc
        command: ["wofi", "--show", "drun"]
        onExited: code => { root.wofiOpen = false }
    }

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
            // SVG is already white — no colorization needed
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited:  root.hovered = false

        onClicked: {
            if (root.wofiOpen) {
                wofiProc.kill()
                // wofiOpen reset to false by onExited
            } else {
                wofiProc.running = true
                root.wofiOpen = true
            }
        }
    }
}
```

- [ ] **Step 4: Verify file exists**

```bash
ls /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/AppMenuButton.qml
```

Expected: file exists, non-zero size.

- [ ] **Step 5: Commit**

```bash
git add flakes/Quickpanel/qml/icons/appmenu.svg flakes/Quickpanel/qml/AppMenuButton.qml
git commit -m "feat: add AppMenuButton with wofi toggle and 9-dot SVG icon"
```

---

## Chunk 5: QML — Dock.qml Restructure

### Task 5: Add pinnedApps list and restructure icon row in Dock.qml

**Files:**
- Modify: `flakes/Quickpanel/qml/Dock.qml`

**Context:** The current `iconRow` contains only a `Repeater` over `Hyprland.toplevels.values`. It needs to be extended with: (1) a `Repeater` over `pinnedApps` using `PinnedItem`, (2) a separator `Rectangle`, (3) the existing window `Repeater` using `DockItem`, (4) a new `AppMenuButton`. The `emptyWorkspace` logic, `refreshEmpty()`, both `Connections` blocks, and all animation/sizing properties must not change.

- [ ] **Step 1: Add pinnedApps list and openWindowCount to Dock.qml**

After the `emptyWorkspace` property (around line 48), add:

```qml
    readonly property var pinnedApps: [
        { name: "Ghostty",     "class": "com.mitchellh.ghostty", exec: "ghostty" },
        { name: "Zen Browser", "class": "zen",                   exec: "zen" },
        { name: "Vesktop",     "class": "vesktop",               exec: "vesktop" },
        { name: "Spotify",     "class": "spotify",               exec: "spotify" },
        { name: "Steam",       "class": "steam",                 exec: "steam" },
    ]

    readonly property int openWindowCount: {
        var count = 0
        var tls = Hyprland.toplevels.values
        for (var i = 0; i < tls.length; i++)
            if (!tls[i].lastIpcObject.floating) count++
        return count
    }
```

> **Note:** `tooltipOverhead` and the updated `implicitHeight` were already added in Chunk 2 (Task 2). Do NOT add them again. Verify they exist: `grep -n "tooltipOverhead" flakes/Quickpanel/qml/Dock.qml` — if found, skip to Step 2.

- [ ] **Step 2: Restructure iconRow**

Replace the entire `RowLayout { id: iconRow ... }` block (currently contains only the `Repeater` over toplevels) with:

```qml
            RowLayout {
                id: iconRow
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:           parent.left
                    right:          parent.right
                    leftMargin:     root.dockPad
                    rightMargin:    root.dockPad
                }
                spacing: root.dockGap

                // ── Pinned apps ───────────────────────────────────────────────
                Repeater {
                    model: root.pinnedApps

                    PinnedItem {
                        required property var modelData

                        panel:      root
                        pinnedApp:  modelData
                    }
                }

                // ── Separator ─────────────────────────────────────────────────
                Rectangle {
                    visible:        root.openWindowCount > 0
                    width:          1
                    height:         root.iconBase * 0.75
                    color:          Qt.rgba(0.627, 0.082, 0.996, 0.35)
                    Layout.alignment: Qt.AlignVCenter
                }

                // ── Open windows ──────────────────────────────────────────────
                Repeater {
                    model: Hyprland.toplevels.values

                    DockItem {
                        required property var modelData
                        required property int index

                        panel:    root
                        client:   modelData
                        isActive: modelData.activated

                        onFocusRequested: function(address) {
                            Hyprland.dispatch("focuswindow address:" + address)
                        }
                    }
                }

                // ── App menu button ───────────────────────────────────────────
                AppMenuButton {
                    panel: root
                }
            }
```

- [ ] **Step 3: Verify the restructure**

```bash
grep -n "PinnedItem\|AppMenuButton\|pinnedApps\|openWindowCount\|tooltipOverhead" \
  /home/luna/nixos/dotfiles/flakes/Quickpanel/qml/Dock.qml
```

Expected: each term appears exactly once (not doubled).

- [ ] **Step 4: Commit**

```bash
git add flakes/Quickpanel/qml/Dock.qml
git commit -m "feat: add pinned apps, separator, and app menu button to dock"
```

---

---

## Chunk 6: Nix — flake.nix xdg.configFile fix

### Task 6: Fix flake.nix to handle icons/ subdirectory and new QML files

**Files:**
- Modify: `flakes/Quickpanel/flake.nix`

**Context:** The current `xdg.configFile` mapping uses `builtins.readDir` + `mapAttrs'` which only works for flat regular files. After adding `icons/` (a directory), the loop must skip directories. The `icons/` directory needs a separate mapping with `recursive = true`. Also, `dockFiles` must include the two new components so they are excluded when `dock.enable = false`.

- [ ] **Step 1: Update xdg.configFile block in flake.nix**

Find the `xdg.configFile` assignment (around line 119) and replace it with:

```nix
            xdg.configFile =
              let
                allFiles  = builtins.readDir qmlSrc;
                dockFiles = [ "Dock.qml" "DockItem.qml" "PinnedItem.qml" "AppMenuButton.qml" ];
                filtered  = if cfg.dock.enable
                            then lib.filterAttrs (_: t: t == "regular") allFiles
                            else lib.filterAttrs (n: t: t == "regular" && !(builtins.elem n dockFiles)) allFiles;
                fileMappings = lib.mapAttrs' (name: _:
                  lib.nameValuePair
                    ("quickshell/" + name)
                    { source = "${qmlSrc}/${name}"; }
                ) filtered;
                iconMapping = lib.optionalAttrs cfg.dock.enable {
                  "quickshell/icons" = { source = "${qmlSrc}/icons"; recursive = true; };
                };
              in fileMappings // iconMapping;
```

- [ ] **Step 2: Verify Nix syntax**

```bash
nix-instantiate --parse /home/luna/nixos/dotfiles/flakes/Quickpanel/flake.nix
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add flakes/Quickpanel/flake.nix
git commit -m "fix: handle icons/ subdirectory in xdg.configFile, add new dock components to dockFiles"
```

---

## Chunk 7: Rebuild & Manual Verification

### Task 7: Rebuild NixOS and verify everything works

**Context:** After all code changes, rebuild the home-manager configuration. Then verify each feature manually.

- [ ] **Step 1: Rebuild home-manager**

```bash
cd /home/luna/nixos/dotfiles
sudo nixos-rebuild switch --flake .#laptop
```

Or if using home-manager standalone:
```bash
home-manager switch --flake .#luna
```

Expected: build succeeds, no errors.

- [ ] **Step 2: Restart Quickshell**

```bash
systemctl --user restart quickshell
```

Or kill and relaunch:
```bash
pkill qs; sleep 1; qs &
```

- [ ] **Step 3: Verify icons load**

Navigate to an empty workspace. The dock should appear. Check:
- All 5 pinned app icons show actual icons (Ghostty terminal icon, Zen fox/browser icon, Vesktop Discord-like icon, Spotify green, Steam) — not `?`
- Open one window, check it also shows the correct icon in the window section

- [ ] **Step 4: Verify tooltip shows full text**

Hover over a pinned app icon. The tooltip should appear above the icon with the full app name, not clipped.

- [ ] **Step 5: Verify click-to-focus**

Open Ghostty on workspace 2, navigate to workspace 1 (empty). Dock appears. Click the Ghostty pinned item. Expected: jumps to workspace 2, Ghostty focused. Active dot should be lit on the Ghostty item when on workspace 2.

- [ ] **Step 6: Verify launch from dock**

On an empty workspace with Ghostty not running, click the Ghostty pinned item. Expected: Ghostty launches.

- [ ] **Step 7: Verify App Menu Button**

Click the 9-dot button on the right of the dock. Expected: wofi drun opens. Click again. Expected: wofi closes. Press Escape in wofi. Click button again. Expected: wofi opens again (state correctly reset).

- [ ] **Step 8: Verify separator visibility**

On empty workspace (no windows open): separator between pinned apps and window section should not be visible. Open one window and go back to an empty workspace — separator should appear when windows are open elsewhere, the window section shows them.

> **Note:** Separator visibility depends on `openWindowCount` which counts toplevels across all workspaces. If you have windows open on other workspaces, the separator will be visible even on an empty workspace. This is expected behavior.

- [ ] **Step 9: Verify dock.enable = false still excludes new files**

Temporarily set `dock.enable = false` in `home/luna/home.nix` (`programs.quickpanel.dock.enable = false;`), then run a dry evaluation:

```bash
cd /home/luna/nixos/dotfiles
nix eval .#homeConfigurations.luna.config.xdg.configFile --apply 'files: builtins.attrNames files' 2>&1 | grep quickshell
```

Expected: `quickshell/Dock.qml`, `quickshell/DockItem.qml`, `quickshell/PinnedItem.qml`, `quickshell/AppMenuButton.qml`, and `quickshell/icons` are **absent** from the output. Revert `dock.enable` to `true` afterward.
