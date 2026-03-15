# Quickpanel Neon Grid Redesign — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Quickpanel QML UI from a dull glassmorphism look to a Cyber/Synthwave Neon Grid style — 560px wide, opaque dark cards, neon colors, icon badges (no overlap), larger buttons.

**Architecture:** Six QML files are modified in-place; no new files are created. Changes are purely visual — data sources, processes, IPC, and Dock are untouched. Tasks 1 and 3–6 are each self-contained, but **after Task 2 the panel will have binding warnings** (old palette names `cSurface`, `cOverlay`, `cAccent` removed before child files are updated) — this resolves after Tasks 3–6. Full visual correctness requires all 6 tasks.

**Tech Stack:** Quickshell (QML/Qt), Hyprland layer-shell, Nerd Font icons via Unicode glyphs, playerctl + nmcli + bluetoothctl + upower for data.

**Spec:** `docs/superpowers/specs/2026-03-15-quickpanel-redesign-design.md`

---

## Chunk 1: Foundation — CtrlButton + QuickPanel

### Task 1: CtrlButton.qml — rename property, larger size, new hover color

**Files:**
- Modify: `flakes/Quickpanel/qml/CtrlButton.qml`

Context: `CtrlButton` is a small `RoundButton` used by `PlayerTab` for media controls. It currently has `required property string iconText`, `implicitWidth/Height: 40`, and hover color `cOverlay`. We rename the property, increase size to 48, and change hover to `cBorder` (which will be defined in the new palette — for now `#1e1e3a`).

- [ ] **Step 1: Open the file and read it**

  Read `flakes/Quickpanel/qml/CtrlButton.qml` to confirm current state before editing.

- [ ] **Step 2: Rename `iconText` property declaration**

  In the property declarations block, change:
  ```qml
  required property string iconText
  ```
  to:
  ```qml
  required property string icon
  ```

- [ ] **Step 3: Update internal reference in contentItem**

  In the `contentItem: Text { ... }` block, change:
  ```qml
  text: iconText
  ```
  to:
  ```qml
  text: icon
  ```

- [ ] **Step 4: Increase implicit size to 48px**

  Change:
  ```qml
  implicitWidth:  40
  implicitHeight: 40
  ```
  to:
  ```qml
  implicitWidth:  48
  implicitHeight: 48
  ```

- [ ] **Step 5: Update hover and accent colors in background Rectangle**

  The `background: Rectangle` uses `panel.cAccent` for the accent state and `panel.cOverlay` for hover. Replace the entire color expression:
  ```qml
  color:  parent.accent ? panel.cAccent
                        : (parent.hovered ? panel.cOverlay : "transparent")
  ```
  with:
  ```qml
  color:  parent.accent ? panel.cNeonCyan
                        : (parent.hovered ? panel.cBorder : "transparent")
  ```
  This replaces both `cAccent` (removed in new palette — play/pause button background becomes `cNeonCyan`) and `cOverlay` (replaced by `cBorder` for hover). `cBorder` and `cNeonCyan` will be defined in the new palette (Task 2).

- [ ] **Step 6: Commit**

  ```bash
  git add flakes/Quickpanel/qml/CtrlButton.qml
  git commit -m "refactor(quickpanel): rename iconText→icon, size 48px, hover cBorder in CtrlButton"
  ```

---

### Task 2: QuickPanel.qml — new palette, 560px width, custom Tab-Bar

**Files:**
- Modify: `flakes/Quickpanel/qml/QuickPanel.qml`

Context: `QuickPanel.qml` is the root `PanelWindow`. It holds the colour palette (read by all child components via `panel: root`), the size, the layer-shell setup, the background `Rectangle`, and the `TabBar` + `StackLayout`. We replace the entire colour block, widen the panel, remove the glassmorphism rectangle (keep it opaque, remove `layer.effect`), replace `TabBar` with a custom pill-toggle-bar, and update margins.

- [ ] **Step 1: Read the file**

  Read `flakes/Quickpanel/qml/QuickPanel.qml` to confirm current state.

- [ ] **Step 2: Replace the colour palette block**

  Find and replace the entire old colour block (exact text to match):
  ```qml
      // ── Colours ───────────────────────────────────────────────────────────────
      readonly property color cBase:    "#1e1e2e"
      readonly property color cSurface: "#313244"
      readonly property color cOverlay: "#45475a"
      readonly property color cText:    "#cdd6f4"
      readonly property color cSubtext: "#a6adc8"
      readonly property color cAccent:  "#89b4fa"
      readonly property color cGreen:   "#a6e3a1"
      readonly property color cRed:     "#f38ba8"
      readonly property color cYellow:  "#f9e2af"
  ```
  Replace with:
  ```qml
      // ── Colours ───────────────────────────────────────────────────────────────
      readonly property color cBase:       "#0a0a12"
      readonly property color cCard:       "#11111f"
      readonly property color cBorder:     "#1e1e3a"
      readonly property color cText:       "#e8e8ff"
      readonly property color cSubtext:    "#7070a0"
      readonly property color cNeonCyan:   "#00f5ff"
      readonly property color cNeonPink:   "#ff2d78"
      readonly property color cNeonViolet: "#bf00ff"
      readonly property color cNeonYellow: "#ffe600"
  ```
  Note: `cSurface`, `cOverlay`, `cAccent`, `cGreen`, `cRed`, `cYellow` are removed. Child components still reference them — binding warnings will appear until Tasks 3–6 update those files.

- [ ] **Step 3: Update panel width**

  Change:
  ```qml
  implicitWidth:  360
  ```
  to:
  ```qml
  implicitWidth:  560
  ```

- [ ] **Step 4a: Update PanelWindow margins**

  Find the exact old `margins` block in `PanelWindow`:
  ```qml
      margins {
          top:   52    // below a typical top bar
          right: 12
      }
  ```
  Replace with (drop the comment, change `right` from 12 to 14):
  ```qml
      margins {
          top:   52
          right: 14
      }
  ```

- [ ] **Step 4b: Update contentCol anchors padding**

  Find the exact old anchors block in `ColumnLayout { id: contentCol`:
  ```qml
          topMargin:    12
          leftMargin:   12
          rightMargin:  12
  ```
  Replace with:
  ```qml
          topMargin:    14
          leftMargin:   14
          rightMargin:  14
  ```

- [ ] **Step 5: Update background Rectangle**

  Find the exact old background block:
  ```qml
      Rectangle {
          anchors.fill: parent
          color:        root.cBase
          radius:       14
          border.color: root.cOverlay
          border.width: 1

          // Drop shadow via a second rectangle behind
          layer.enabled: true
          layer.effect: null   // replace with MultiEffect if available
      }
  ```
  Replace with (remove `layer.*` lines, update colors and radius):
  ```qml
      Rectangle {
          anchors.fill: parent
          color:        root.cBase
          radius:       16
          border.color: root.cBorder
          border.width: 1
      }
  ```

- [ ] **Step 6: Replace TabBar with custom pill-toggle-bar**

  Remove the entire `TabBar { ... }` block (including both `TabButton` children). Replace with:
  ```qml
  // ── Custom Tab Toggle Bar ─────────────────────────────────────────────────
  Item {
      id: tabToggle
      Layout.fillWidth: true
      Layout.bottomMargin: 10
      implicitHeight: 36

      property int currentIndex: 0

      // Animated neon underline indicator
      Rectangle {
          id: tabIndicator
          width:  tabToggle.width / 2
          height: 3
          radius: 1.5
          color:  root.cNeonCyan
          anchors.bottom: parent.bottom

          x: tabToggle.currentIndex * (tabToggle.width / 2)
          Behavior on x {
              NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }
      }

      Row {
          anchors.fill: parent

          // Status tab button
          Rectangle {
              width:  tabToggle.width / 2
              height: tabToggle.implicitHeight
              color:  "transparent"

              Text {
                  anchors.centerIn: parent
                  text:  "  Status"
                  font.pixelSize: 13
                  font.weight:    Font.Medium
                  color: tabToggle.currentIndex === 0 ? root.cNeonCyan : root.cSubtext
              }

              MouseArea {
                  anchors.fill: parent
                  onClicked: tabToggle.currentIndex = 0
              }
          }

          // Player tab button
          Rectangle {
              width:  tabToggle.width / 2
              height: tabToggle.implicitHeight
              color:  "transparent"

              Text {
                  anchors.centerIn: parent
                  text:  "  Player"
                  font.pixelSize: 13
                  font.weight:    Font.Medium
                  color: tabToggle.currentIndex === 1 ? root.cNeonCyan : root.cSubtext
              }

              MouseArea {
                  anchors.fill: parent
                  onClicked: tabToggle.currentIndex = 1
              }
          }
      }
  }
  ```

- [ ] **Step 7: Update StackLayout to use tabToggle**

  Find the exact old string (note the alignment whitespace):
  ```qml
          currentIndex:      tabBar.currentIndex
  ```
  Replace with:
  ```qml
          currentIndex:      tabToggle.currentIndex
  ```

- [ ] **Step 8: Update implicitHeight formula**

  Change:
  ```qml
  implicitHeight: contentCol.implicitHeight + 24
  ```
  to:
  ```qml
  implicitHeight: contentCol.implicitHeight + 28
  ```

- [ ] **Step 9: Commit**

  ```bash
  git add flakes/Quickpanel/qml/QuickPanel.qml
  git commit -m "feat(quickpanel): neon palette, 560px width, custom tab-bar, remove glassmorphism"
  ```

---

## Chunk 2: StatusTab Components

### Task 3: StatusRow.qml — badge system, larger height

**Files:**
- Modify: `flakes/Quickpanel/qml/StatusRow.qml`

Context: `StatusRow` is a generic `Rectangle` row used for WiFi and Bluetooth. Currently `implicitHeight: 44`, icon displayed naked as a `Text`. We add an optional `badgeColor` property and wrap the icon in a badge when set.

- [ ] **Step 1: Read the file**

  Read `flakes/Quickpanel/qml/StatusRow.qml`.

- [ ] **Step 2: Add badgeColor property and increase height**

  After the existing property declarations, add:
  ```qml
  property color badgeColor: "transparent"
  ```
  Change:
  ```qml
  implicitHeight: 44
  color:          panel.cSurface
  ```
  to:
  ```qml
  implicitHeight: 68
  color:          panel.cCard
  ```

- [ ] **Step 3: Replace the icon Text with a badge+icon block**

  Find the icon `Text` item:
  ```qml
  // Icon
  Text {
      text:           icon
      font.pixelSize: 16
      color:          iconColor
  }
  ```
  Replace with:
  ```qml
  // Icon badge
  Rectangle {
      width:  32
      height: 32
      radius: 8
      color:  Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.15)

      Text {
          anchors.centerIn: parent
          text:           icon
          font.pixelSize: 20
          color:          iconColor
      }
  }
  ```

- [ ] **Step 4: Update value font size and max-width**

  The label `Text` ("WiFi", "Bluetooth") keeps `font.pixelSize: 13` — no change needed.

  Find the value `Text` block (rightmost element, has `Layout.maximumWidth`):
  ```qml
      // Value
      Text {
          text:                value
          font.pixelSize:      13
          color:               panel.cText
          elide:               Text.ElideRight
          Layout.maximumWidth: 170
      }
  ```
  Replace with:
  ```qml
      // Value
      Text {
          text:                value
          font.pixelSize:      15
          color:               panel.cText
          elide:               Text.ElideRight
          Layout.maximumWidth: 240
      }
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add flakes/Quickpanel/qml/StatusRow.qml
  git commit -m "feat(quickpanel): badge system in StatusRow, height 68px"
  ```

---

### Task 4: BatteryRow.qml — badge, thicker bar, new neon colors

**Files:**
- Modify: `flakes/Quickpanel/qml/BatteryRow.qml`

Context: `BatteryRow` is a `Rectangle` with icon + label + percent text + progress bar. Currently `implicitHeight: 52`, bar `height: 4`. We add a badge wrapper around the icon, increase height to 84, thicken the bar to 6px, and update colors to neon palette.

- [ ] **Step 1: Read the file**

  Read `flakes/Quickpanel/qml/BatteryRow.qml`.

- [ ] **Step 2: Update height and background color**

  Change:
  ```qml
  implicitHeight: 52
  color:          panel.cSurface
  ```
  to:
  ```qml
  implicitHeight: 84
  color:          panel.cCard
  ```

- [ ] **Step 3: Replace battery icon Text with a badge+icon block**

  Find the exact old icon `Text` block in the `RowLayout`:
  ```qml
              Text {
                  text: {
                      if (status === "Charging")    return ""
                      if (pct > 80)                 return ""
                      if (pct > 40)                 return ""
                      if (pct > 15)                 return ""
                      return ""
                  }
                  font.pixelSize: 16
                  color: {
                      if (status === "Charging")    return panel.cGreen
                      if (pct > 40)                 return panel.cText
                      if (pct > 15)                 return panel.cYellow
                      return panel.cRed
                  }
              }
  ```
  Replace with the badge wrapper (larger icon, neon palette):
  ```qml
              // Battery icon badge
              Rectangle {
                  width:  32
                  height: 32
                  radius: 8
                  color:  Qt.rgba(panel.cNeonViolet.r, panel.cNeonViolet.g, panel.cNeonViolet.b, 0.15)

                  Text {
                      anchors.centerIn: parent
                      text: {
                          if (status === "Charging")    return ""
                          if (pct > 80)                 return ""
                          if (pct > 40)                 return ""
                          if (pct > 15)                 return ""
                          return ""
                      }
                      font.pixelSize: 18
                      color: {
                          if (status === "Charging")    return panel.cNeonCyan
                          if (pct >= 41)                return panel.cText
                          if (pct >= 16)                return panel.cNeonYellow
                          return panel.cNeonPink
                      }
                  }
              }
  ```

- [ ] **Step 4: Update the "Battery" label color**

  ```qml
  Text {
      text:           "Battery"
      font.pixelSize: 13
      color:          panel.cSubtext
      font.weight:    Font.Medium
  }
  ```
  (no change needed — just confirm it's using `panel.cSubtext`)

- [ ] **Step 5: Update the percent+status text**

  Change:
  ```qml
  color: panel.cText
  ```
  to keep `panel.cText` (no change). Confirm font size is 13 or bump to 15 to match StatusRow value style:
  ```qml
  font.pixelSize: 15
  ```

- [ ] **Step 6: Update progress bar**

  Find the progress bar `Rectangle` (the track). Change:
  ```qml
  height: 4
  radius: 2
  color:  panel.cOverlay
  ```
  to:
  ```qml
  height: 6
  radius: 3
  color:  panel.cBorder
  ```

  Find the fill `Rectangle` inside it. Replace its old color expression:
  ```qml
                  color: {
                      if (status === "Charging") return panel.cGreen
                      if (pct > 40)              return panel.cAccent
                      if (pct > 15)              return panel.cYellow
                      return panel.cRed
                  }
  ```
  with the new neon version:
  ```qml
                  color: {
                      if (status === "Charging") return panel.cNeonCyan
                      if (pct >= 41)             return panel.cNeonViolet
                      if (pct >= 16)             return panel.cNeonYellow
                      return panel.cNeonPink
                  }
  ```

- [ ] **Step 7: Commit**

  ```bash
  git add flakes/Quickpanel/qml/BatteryRow.qml
  git commit -m "feat(quickpanel): neon battery badge, thicker bar, updated color thresholds"
  ```

---

### Task 5: StatusTab.qml — neon clock with glow fallback, badge colors for rows

**Files:**
- Modify: `flakes/Quickpanel/qml/StatusTab.qml`

Context: `StatusTab` contains the clock block, and three rows (WiFi, BT, Battery). We need to: replace the clock block with a neon version using the double-Text glow trick, increase clock card height to 100, and pass `badgeColor` + updated colors to the rows.

- [ ] **Step 1: Read the file**

  Read `flakes/Quickpanel/qml/StatusTab.qml`.

- [ ] **Step 2: Update clock Rectangle**

  Find the clock card `Rectangle` (`implicitHeight: 72`). Change:
  ```qml
  implicitHeight: 72
  color:   panel.cSurface
  radius:  10
  ```
  to:
  ```qml
  implicitHeight: 100
  color:   panel.cCard
  radius:  12
  border.color: panel.cBorder
  border.width: 1
  ```

- [ ] **Step 3: Replace the clock ColumnLayout with stacked glow + main text**

  The glow effect requires both texts to overlap (not stack vertically). Replace the entire inner `ColumnLayout` of the clock card with an `Item` containing two stacked `Text` elements.

  Find the inner `ColumnLayout` of the clock card (starts right after `Rectangle { ... implicitHeight: 72 ... ColumnLayout {`):
  ```qml
              ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                      id: clockLabel
                      Layout.alignment: Qt.AlignHCenter
                      font.pixelSize:   34
                      font.weight:      Font.Light
                      color:            panel.cText

                      property string timeStr: ""
                      property string dateStr: ""

                      text: timeStr

                      function updateTime() {
                          var d   = new Date()
                          var h   = d.getHours().toString().padStart(2, "0")
                          var m   = d.getMinutes().toString().padStart(2, "0")
                          var s   = d.getSeconds().toString().padStart(2, "0")
                          timeStr = h + ":" + m + ":" + s

                          var days   = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                          var months = ["Jan","Feb","Mar","Apr","May","Jun",
                                        "Jul","Aug","Sep","Oct","Nov","Dec"]
                          dateStr = days[d.getDay()] + ", " +
                                    d.getDate() + " " + months[d.getMonth()] +
                                    " " + d.getFullYear()
                      }
                  }

                  Text {
                      Layout.alignment: Qt.AlignHCenter
                      text:             clockLabel.dateStr
                      font.pixelSize:   12
                      color:            panel.cSubtext
                  }
              }
  ```
  Replace with:
  ```qml
  Item {
      anchors.centerIn: parent
      width: clockLabel.width
      height: clockLabel.height

      // Glow layer
      Text {
          anchors.centerIn: parent
          font.pixelSize:   52
          font.weight:      Font.Light
          color:            panel.cNeonCyan
          opacity:          0.30
          text:             clockLabel.timeStr
      }

      // Main clock
      Text {
          id: clockLabel
          anchors.centerIn: parent
          font.pixelSize:   48
          font.weight:      Font.Light
          color:            panel.cNeonCyan

          property string timeStr: ""
          property string dateStr: ""

          text: timeStr

          function updateTime() {
              var d   = new Date()
              var h   = d.getHours().toString().padStart(2, "0")
              var m   = d.getMinutes().toString().padStart(2, "0")
              var s   = d.getSeconds().toString().padStart(2, "0")
              timeStr = h + ":" + m + ":" + s

              var days   = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
              var months = ["Jan","Feb","Mar","Apr","May","Jun",
                            "Jul","Aug","Sep","Oct","Nov","Dec"]
              dateStr = days[d.getDay()] + ", " +
                        d.getDate() + " " + months[d.getMonth()] +
                        " " + d.getFullYear()
          }
      }
  }

  Text {
      Layout.alignment: Qt.AlignHCenter
      text:             clockLabel.dateStr
      font.pixelSize:   14
      color:            panel.cSubtext
  }
  ```

- [ ] **Step 4: Update WiFi StatusRow call**

  Find the WiFi `StatusRow` block. Add `badgeColor` and update `iconColor`:
  ```qml
  StatusRow {
      panel:      root.panel
      icon:       root.wifiConnected ? "" : ""
      iconColor:  root.wifiConnected ? panel.cNeonCyan : panel.cNeonPink
      badgeColor: panel.cNeonCyan
      label:      "WiFi"
      value:      root.wifiSSID
  }
  ```

- [ ] **Step 5: Update Bluetooth StatusRow call**

  ```qml
  StatusRow {
      panel:      root.panel
      icon:       ""
      iconColor:  root.btEnabled ? panel.cNeonPink : panel.cSubtext
      badgeColor: panel.cNeonPink
      label:      "Bluetooth"
      value:      root.btStatus + (root.btDevice.length > 0
                      ? "  ·  " + root.btDevice : "")
  }
  ```

- [ ] **Step 6: Update BatteryRow call**

  No new properties needed — `BatteryRow` reads colors directly from panel. Just confirm it still receives `panel: root.panel`.

- [ ] **Step 7: Commit**

  ```bash
  git add flakes/Quickpanel/qml/StatusTab.qml
  git commit -m "feat(quickpanel): neon clock with glow, badge colors for wifi+bt rows"
  ```

---

## Chunk 3: PlayerTab

### Task 6: PlayerTab.qml — bigger track card, new controls, neon slider

**Files:**
- Modify: `flakes/Quickpanel/qml/PlayerTab.qml`

Context: `PlayerTab` contains the track-info card, playback controls row, and volume row. We increase the track card, update album art placeholder size, change text colors, fix all `iconText:` → `icon:` call sites, and update the volume slider.

- [ ] **Step 1: Read the file**

  Read `flakes/Quickpanel/qml/PlayerTab.qml`.

- [ ] **Step 2: Update track-info card**

  Find the track-info `Rectangle` (`implicitHeight: 80`). Change:
  ```qml
  implicitHeight: 80
  color:          panel.cSurface
  radius:         10
  ```
  to:
  ```qml
  implicitHeight: 96
  color:          panel.cCard
  radius:         12
  border.color:   panel.cBorder
  border.width:   1
  ```

- [ ] **Step 3: Update album art placeholder**

  Find the album art `Rectangle` (`width: 52, height: 52`). Change:
  ```qml
  width:  52
  height: 52
  radius: 6
  color:  panel.cOverlay
  ```
  to:
  ```qml
  width:  72
  height: 72
  radius: 10
  color:  panel.cCard
  border.color: panel.cBorder
  border.width: 1
  ```
  Update the icon inside it:
  ```qml
  Text {
      anchors.centerIn: parent
      text:             ""
      font.pixelSize:   28
      color:            panel.cNeonViolet
  }
  ```

- [ ] **Step 4: Update artist and album text colors**

  Title keeps `color: panel.cText` — no change.

  Find artist `Text` (second Text in the track-info ColumnLayout):
  ```qml
                      Text {
                          Layout.fillWidth: true
                          text:             root.trackArtist || (root.playerName.length > 0
                                                ? root.playerName : " ")
                          font.pixelSize:   12
                          color:            panel.cSubtext
                          elide:            Text.ElideRight
                      }
  ```
  Replace `color: panel.cSubtext` with `color: panel.cNeonCyan`.

  Find album `Text` (third Text, has `visible: root.trackAlbum.length > 0`):
  ```qml
                      Text {
                          Layout.fillWidth: true
                          text:             root.trackAlbum
                          font.pixelSize:   11
                          color:            panel.cOverlay
                          elide:            Text.ElideRight
                          visible:          root.trackAlbum.length > 0
                      }
  ```
  Replace `color: panel.cOverlay` with `color: panel.cSubtext`.

- [ ] **Step 5: Update controls card**

  Find the controls `Rectangle` (`implicitHeight: 56`). Change:
  ```qml
  implicitHeight: 56
  color:          panel.cSurface
  radius:         10
  ```
  to:
  ```qml
  implicitHeight: 68
  color:          panel.cCard
  radius:         12
  border.color:   panel.cBorder
  border.width:   1
  ```

- [ ] **Step 6: Fix all iconText → icon call sites (4 places)**

  Find and replace each of the four `CtrlButton` blocks. Old → new for each:

  Previous button — find:
  ```qml
                  CtrlButton {
                      panel:  root.panel
                      iconText:   ""
                      onClicked: root.runCmd("previous")
                  }
  ```
  Replace with:
  ```qml
                  CtrlButton {
                      panel:    root.panel
                      icon:     ""
                      onClicked: root.runCmd("previous")
                  }
  ```

  Play/Pause button — find:
  ```qml
                  CtrlButton {
                      panel:     root.panel
                      iconText:      root.isPlaying ? "" : ""
                      accent:    true
                      iconSize:  22
                      onClicked: root.runCmd("play-pause")
                  }
  ```
  Replace with:
  ```qml
                  CtrlButton {
                      panel:     root.panel
                      icon:      root.isPlaying ? "" : ""
                      accent:    true
                      iconSize:  26
                      onClicked: root.runCmd("play-pause")
                  }
  ```
  Note: `iconSize` also changes from 22 to 26 here per the spec.

  Next button — find:
  ```qml
                  CtrlButton {
                      panel:  root.panel
                      iconText:   ""
                      onClicked: root.runCmd("next")
                  }
  ```
  Replace with:
  ```qml
                  CtrlButton {
                      panel:    root.panel
                      icon:     ""
                      onClicked: root.runCmd("next")
                  }
  ```

  Stop button — find:
  ```qml
                  CtrlButton {
                      panel:  root.panel
                      iconText:   ""
                      onClicked: root.runCmd("stop")
                  }
  ```
  Replace with:
  ```qml
                  CtrlButton {
                      panel:    root.panel
                      icon:     ""
                      onClicked: root.runCmd("stop")
                  }
  ```

- [ ] **Step 7: Update volume card**

  Find the volume `Rectangle` (`implicitHeight: 44`). Change:
  ```qml
  implicitHeight: 44
  color:          panel.cSurface
  radius:         10
  ```
  to:
  ```qml
  implicitHeight: 64
  color:          panel.cCard
  radius:         12
  border.color:   panel.cBorder
  border.width:   1
  ```

- [ ] **Step 8: Update slider track**

  Find the slider `background: Rectangle`. Change:
  ```qml
  height: 4
  radius: 2
  color:  panel.cOverlay
  ```
  to:
  ```qml
  height: 6
  radius: 3
  color:  panel.cBorder
  ```
  Find and replace the fill `Rectangle`'s old color (inside the slider background):
  ```qml
                      Rectangle {
                          width:  volSlider.visualPosition * parent.width
                          height: parent.height
                          radius: parent.radius
                          color:  panel.cAccent
                      }
  ```
  Replace `color: panel.cAccent` with `color: panel.cNeonCyan`.

- [ ] **Step 9: Update slider handle**

  Change:
  ```qml
  width:  14
  height: 14
  radius: 7
  color:  panel.cText
  ```
  to:
  ```qml
  width:  16
  height: 16
  radius: 8
  color:  panel.cNeonCyan
  ```

- [ ] **Step 10: Update volume percent text color**

  Change the trailing percent `Text`:
  ```qml
  color: panel.cSubtext
  ```
  to:
  ```qml
  color: panel.cNeonCyan
  ```

- [ ] **Step 11: Commit**

  ```bash
  git add flakes/Quickpanel/qml/PlayerTab.qml
  git commit -m "feat(quickpanel): neon player card, larger album art, neon slider, fix iconText→icon"
  ```

---

## Final Verification

- [ ] **Reload Quickshell** — run `qs` or restart the systemd service:
  ```bash
  systemctl --user restart quickshell
  ```
  Or if running manually:
  ```bash
  qs --config ~/.config/quickshell/
  ```

- [ ] **Visual checklist:**
  - Panel is ~560px wide ✓
  - Background is deep black, no frosted glass ✓
  - Clock is large (48px) and cyan ✓
  - WiFi/BT/Battery rows have badge icons, no overlap ✓
  - Tab underline animates smoothly on switch ✓
  - Player controls are 48×48px, clickable ✓
  - Volume slider is cyan, thicker ✓

- [ ] **Final commit (if any fixups needed)**
  ```bash
  git add -p
  git commit -m "fix(quickpanel): post-reload visual fixups"
  ```
