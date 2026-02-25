import QtQuick
import QtQuick.Layouts
import Quickshell

import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Bluetooth

PanelWindow {
  id: bar
  anchors { top: true; left: true; right: true }
  implicitHeight: 34

  GlassRect {
    anchors.fill: parent
    radius: 12
    opacity: 0.78
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    WorkspaceSwitcher { Layout.alignment: Qt.AlignVCenter }

    Item { Layout.fillWidth: true }

    MprisMini {
      Layout.alignment: Qt.AlignVCenter
      maxWidth: 420
    }

    Item { Layout.fillWidth: true }

    WifiIndicator { Layout.alignment: Qt.AlignVCenter }
    BluetoothIndicator { Layout.alignment: Qt.AlignVCenter }
    Tray { Layout.alignment: Qt.AlignVCenter }

    Text {
      Layout.alignment: Qt.AlignVCenter
      text: Qt.formatDateTime(new Date(), "ddd  HH:mm")
      font.pixelSize: 12
      color: "white"
      opacity: 0.95
    }
  }
}
