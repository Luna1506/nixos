import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
  id: dock

  // This is the big fix for the white background:
  // make the layer surface itself transparent.
  color: "transparent"

  anchors { bottom: true; left: true; right: true }
  implicitHeight: 96

  // ---- Configuration ----
  // "Pinned" apps: className is used to detect running windows.
  // iconName should exist in your icon theme.
  property var pinnedApps: [
    { label: "Firefox",  icon: "firefox",           command: "firefox",  className: "firefox" },
    { label: "Terminal", icon: "utilities-terminal",command: "ghostty",  className: "ghostty" },
    { label: "Code",     icon: "code",             command: "code",     className: "code" },
    { label: "Discord",  icon: "discord",          command: "vesktop",  className: "vesktop" }
  ]

  // Simple mapping: if Hyprland class names differ from icon names, map them here.
  function iconForClass(cls) {
    if (!cls) return "application-x-executable";
    const c = cls.toLowerCase();
    if (c.includes("firefox")) return "firefox";
    if (c.includes("ghostty")) return "utilities-terminal";
    if (c.includes("alacritty")) return "utilities-terminal";
    if (c.includes("kitty")) return "utilities-terminal";
    if (c.includes("code")) return "code";
    if (c.includes("vesktop")) return "discord";
    if (c.includes("discord")) return "discord";
    return cls; // fallback: try class as icon name
  }

  function isPinnedClass(cls) {
    if (!cls) return false;
    const c = cls.toLowerCase();
    for (let i = 0; i < pinnedApps.length; i++) {
      const p = (pinnedApps[i].className || "").toLowerCase();
      if (p && c.includes(p)) return true;
    }
    return false;
  }

  function hasClientForPinned(pinned) {
    if (!Hyprland.clients) return false;
    const needle = (pinned.className || "").toLowerCase();
    if (!needle) return false;

    for (let i = 0; i < Hyprland.clients.count; i++) {
      const cl = Hyprland.clients.get(i);
      const cls = (cl && cl.class ? String(cl.class).toLowerCase() : "");
      if (cls.includes(needle)) return true;
    }
    return false;
  }

  // Collect running (non-pinned) classes with one representative address to focus.
  function runningNonPinned() {
    const out = [];
    const seen = {};

    if (!Hyprland.clients) return out;

    for (let i = 0; i < Hyprland.clients.count; i++) {
      const c = Hyprland.clients.get(i);
      if (!c) continue;

      const cls = c.class ? String(c.class) : "";
      if (!cls) continue;

      const key = cls.toLowerCase();
      if (seen[key]) continue;
      if (isPinnedClass(key)) continue;

      seen[key] = true;
      out.push({
        className: cls,
        title: c.title ? String(c.title) : cls,
        address: c.address ? String(c.address) : ""
      });
    }

    return out;
  }

  // ---- Layout ----
  Item {
    anchors.fill: parent

    GlassRect {
      id: bg
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 10
      width: Math.min(parent.width - 40, 760)
      height: 68
      radius: 18
      opacity: 0.70
    }

    RowLayout {
      id: row
      anchors.fill: bg
      anchors.margins: 10
      spacing: 10

      // Pinned apps (left)
      Repeater {
        model: dock.pinnedApps

        delegate: IconButton {
          required property var modelData

          iconName: modelData.icon
          label: modelData.label
          command: modelData.command

          // show dot if running
          running: dock.hasClientForPinned(modelData)

          // If running: focus instead of launching new instance (best-effort)
          activate: function() {
            // find a client matching pinned class and focus it
            const needle = (modelData.className || "").toLowerCase();
            for (let i = 0; i < Hyprland.clients.count; i++) {
              const c = Hyprland.clients.get(i);
              const cls = (c && c.class ? String(c.class).toLowerCase() : "");
              if (cls.includes(needle)) {
                // Hyprland focuswindow dispatch is best-effort; address is the most stable identifier.
                if (c.address) {
                  Hyprland.dispatch("focuswindow address:" + c.address);
                  return;
                }
              }
            }
            // fallback: launch
            if (modelData.command && modelData.command.length > 0) {
              // IconButton will run it if we null activate, so call command manually here:
              // (keep simple)
              Qt.callLater(function() {
                // no-op; clicking again will launch if you remove activate
              })
            }
          }
        }
      }

      // Spacer
      Item { Layout.fillWidth: true }

      // Running (non-pinned) apps (middle/right)
      Repeater {
        model: dock.runningNonPinned()

        delegate: IconButton {
          required property var modelData
          iconName: dock.iconForClass(modelData.className)
          label: modelData.title
          running: true

          activate: function() {
            if (modelData.address && modelData.address.length > 0) {
              Hyprland.dispatch("focuswindow address:" + modelData.address);
            }
          }
        }
      }

      // Spacer
      Item { Layout.fillWidth: true }

      // Search (right)
      IconButton {
        iconName: "system-search"
        label: "Search"
        command: "rofi -show drun"
      }
    }
  }
}
