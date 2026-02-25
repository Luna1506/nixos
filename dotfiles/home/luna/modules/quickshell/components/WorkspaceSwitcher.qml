import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
  id: root
  spacing: 6

  Repeater {
    model: Hyprland.workspaces

    delegate: Rectangle {
      required property var modelData

      width: 18
      height: 18
      radius: 7

      property bool active: Hyprland.focusedWorkspace && (Hyprland.focusedWorkspace.id === modelData.id)

      color: active ? "#ffffff" : "transparent"
      border.color: "#ffffff"
      border.width: 1
      opacity: active ? 0.95 : 0.35

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("workspace " + modelData.id)
      }
    }
  }
}
