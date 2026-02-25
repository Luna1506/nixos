import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
  id: root
  spacing: 6

  property bool connected: false
  property string ssid: ""

  Process { id: nmcli }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      nmcli.exec({
        arguments: [
          "sh", "-lc",
          "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}'"
        ],
        onExited: function(_code, _status, stdout, _stderr) {
          const out = (stdout || "").trim()
          root.connected = out.length > 0
          root.ssid = out
        }
      })
    }
  }

  Rectangle {
    width: 18
    height: 18
    radius: 7
    border.color: "#ffffff"
    border.width: 1
    color: "transparent"
    opacity: root.connected ? 0.9 : 0.35
  }
}
