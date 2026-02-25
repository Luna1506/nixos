import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

RowLayout {
  spacing: 6

  Rectangle {
    width: 18
    height: 18
    radius: 7
    border.color: "#ffffff"
    border.width: 1
    color: "transparent"
    opacity: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? 0.9 : 0.35
  }

  Text {
    text: Bluetooth.devices ? (Bluetooth.devices.count > 0 ? ("" + Bluetooth.devices.count) : "") : ""
    color: "white"
    opacity: 0.9
    font.pixelSize: 12
  }
}
