import QtQuick
import qs

// A Material Symbols Rounded glyph. `fill` animates between the outlined
// (0) and filled (1) style.
Text {
    id: root

    property string icon
    property real size: Theme.icon.normal
    property real fill: 0

    text: icon
    color: Theme.colors.text
    font.family: Theme.font.iconFamily
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": root.fill,
            "opsz": Math.max(Theme.icon.opticalSizeMin, Math.min(Theme.icon.opticalSizeMax, root.size)),
            "wght": Theme.icon.weight
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on fill {
        Anim {
            duration: Theme.anim.fast
        }
    }
}
