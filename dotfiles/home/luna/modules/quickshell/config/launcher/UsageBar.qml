import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// One plan limit: label and percentage, a thin bar and the time until the
// window resets. The bar turns to the warning color at high utilization.
ColumnLayout {
    id: root

    property string label
    // 0..1
    property real value: 0
    // ms since epoch, 0 if unknown
    property real resetsAt: 0
    property real now: Date.now()

    readonly property bool high: value >= Config.usageWarnThreshold

    function remaining(ms: real): string {
        const minutes = Math.max(1, Math.round(ms / 60000));
        const d = Math.floor(minutes / 1440);
        const h = Math.floor(minutes % 1440 / 60);
        const m = minutes % 60;
        if (d > 0)
            return d + " d " + h + " h";
        if (h > 0)
            return h + " h " + m + " min";
        return m + " min";
    }

    spacing: Theme.spacing.xs

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.sm

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: Theme.colors.textMuted
            font.pixelSize: Theme.font.small
        }

        StyledText {
            text: Math.round(root.value * 100) + " %"
            color: root.high ? Theme.colors.warning : Theme.colors.text
            font.pixelSize: Theme.font.small
            font.weight: Theme.font.weightMedium
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.size.usageBarHeight
        radius: height / 2
        color: Theme.colors.surfaceHighest

        Rectangle {
            height: parent.height
            width: Math.max(height, parent.width * Math.min(1, root.value))
            radius: height / 2
            color: root.high ? Theme.colors.warning : Theme.colors.primary

            Behavior on width {
                Anim {}
            }

            Behavior on color {
                ColorAnim {}
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.resetsAt > root.now
        text: "Reset in " + root.remaining(root.resetsAt - root.now)
        color: Theme.colors.textMuted
        font.pixelSize: Theme.font.small
    }
}
