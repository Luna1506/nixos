// ─── VolumeSlider.qml ─────────────────────────────────────────────────────────
// Reusable volume slider (0–100).

import QtQuick
import QtQuick.Controls

Slider {
    id: root

    property color trackColor: "#a855f7"

    from:     0
    to:       100
    stepSize: 1

    background: Rectangle {
        x:      root.leftPadding
        y:      root.topPadding + root.availableHeight / 2 - height / 2
        width:  root.availableWidth
        height: 4
        radius: 2
        color:  Qt.rgba(1, 1, 1, 0.10)

        Rectangle {
            width:  root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color:  root.trackColor
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    handle: Rectangle {
        x:      root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y:      root.topPadding + root.availableHeight / 2 - height / 2
        width:  14
        height: 14
        radius: 7
        color:  root.pressed ? Qt.lighter(root.trackColor, 1.3) : root.trackColor
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
