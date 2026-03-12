// ─── CtrlButton.qml ───────────────────────────────────────────────────────────
// Small circular icon button for the player controls.

import QtQuick
import QtQuick.Controls

RoundButton {
    required property var  panel
    required property string icon

    property bool  accent:   false
    property real  iconSize: 18

    implicitWidth:  40
    implicitHeight: 40
    radius:         20

    background: Rectangle {
        radius: parent.radius
        color:  parent.accent ? panel.cAccent
                              : (parent.hovered ? panel.cOverlay : "transparent")

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    contentItem: Text {
        text:                icon
        font.pixelSize:      iconSize
        color:               parent.accent ? panel.cBase : panel.cText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
    }
}
