import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
  id: root
  width: 46
  height: 46

  // iconName should be an icon theme name (best) or desktop-ish name
  property string iconName: "application-x-executable"
  property string label: ""
  property string command: ""

  // Optional: if provided, this is used instead of command execution.
  // Use it to focus an already running window, etc.
  property var activate: null

  // Optional: set true to show a running indicator dot
  property bool running: false

  Process { id: runner }

  Column {
    anchors.centerIn: parent
    spacing: 4

    Rectangle {
      id: hit
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
        // If iconPath can't resolve, source becomes empty -> we draw fallback below
        source: Quickshell.iconPath(root.iconName)
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.95
      }

      // Fallback if iconPath fails (shows first letter)
      Text {
        anchors.centerIn: parent
        visible: (Quickshell.iconPath(root.iconName) === "")
        text: root.label && root.label.length > 0 ? root.label[0].toUpperCase() : "?"
        color: "white"
        opacity: 0.9
        font.pixelSize: 14
      }
    }

    Rectangle {
      width: 6
      height: 6
      radius: 3
      color: "white"
      opacity: root.running ? 0.85 : 0.0
      Behavior on opacity { NumberAnimation { duration: 120 } }
      anchors.horizontalCenter: hit.horizontalCenter
    }
  }

  property bool hovered: false

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: root.hovered = true
    onExited: root.hovered = false
    onClicked: {
      if (root.activate) {
        try { root.activate(); } catch (e) {}
        return;
      }
      if (root.command && root.command.length > 0) {
        runner.exec({ arguments: [ "sh", "-lc", root.command ] })
      }
    }
  }

  ToolTip.visible: hovered && root.label.length > 0
  ToolTip.text: root.label
  ToolTip.delay: 400
}
