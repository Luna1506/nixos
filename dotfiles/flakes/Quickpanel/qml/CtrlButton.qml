// ─── CtrlButton.qml ───────────────────────────────────────────────────────────
// Small circular icon button for the player controls.

import QtQuick
import QtQuick.Controls

RoundButton {
    required property var  panel
    required property string iconText

    property bool  accent:   false
    property real  iconSize: 18

    implicitWidth:  48
    implicitHeight: 48

    background: Rectangle {
        radius: 20
        color:  parent.accent ? panel.cNeonCyan
                              : (parent.hovered ? panel.cBorder : "transparent")

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    contentItem: Text {
        text:                iconText
        font.pixelSize:      iconSize
        color:               parent.accent ? panel.cBase : panel.cText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
    }
}
