import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
  id: root
  width: 46
  height: 46

  property string iconName: "application-x-executable"
  property string label: ""
  property string command: ""

  Process { id: runner }

  Rectangle {
    id: hit
    anchors.centerIn: parent
    width: 44
    height: 44
    radius: 12
    color: "transparent"
    border.color: "#ffffff"
    border.width: 1
    opacity: hovered ? 0.14 : 0.06

    scale: hovered ? 1.18 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Image {
      anchors.centerIn: parent
      width: 26
      height: 26
      source: Quickshell.iconPath(root.iconName)
      fillMode: Image.PreserveAspectFit
      smooth: true
      opacity: 0.95
    }
  }

  property bool hovered: false

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: root.hovered = true
    onExited: root.hovered = false
    onClicked: {
      if (root.command && root.command.length > 0) {
        runner.exec({ arguments: [ "sh", "-lc", root.command ] })
      }
    }
  }

  ToolTip.visible: hovered && root.label.length > 0
  ToolTip.text: root.label
  ToolTip.delay: 400
}
