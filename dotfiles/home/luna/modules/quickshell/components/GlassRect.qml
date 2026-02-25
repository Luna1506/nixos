import QtQuick

Rectangle {
  id: r
  color: "#101014"
  border.color: "#ffffff"
  border.width: 1
  opacity: 0.75

  Rectangle {
    anchors.fill: parent
    radius: r.radius
    color: "transparent"
    border.color: "#ffffff"
    border.width: 1
    opacity: 0.08
  }
}
