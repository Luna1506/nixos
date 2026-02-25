import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
  id: root
  spacing: 6

  Repeater {
    model: SystemTray.items

    delegate: Rectangle {
      required property var modelData

      width: 18
      height: 18
      radius: 6
      color: "transparent"
      border.color: "#ffffff"
      border.width: 1
      opacity: 0.55

      Image {
        anchors.centerIn: parent
        width: 14
        height: 14
        source: modelData.icon ? Quickshell.iconPath(modelData.icon) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.95
      }
    }
  }
}
