import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

ColumnLayout {
    id: root

    readonly property bool usable: NetworkState.usable
    readonly property var others: NetworkState.networks.filter(n => !n.connected)

    spacing: Theme.spacing.md

    DetailHeader {
        Layout.fillWidth: true
        title: "Wi-Fi"
        showSwitch: NetworkState.wifiAvailable
        checked: NetworkState.wifiEnabled
        switchEnabled: !NetworkState.wifiBlockedByHardware
        onToggled: NetworkState.toggleWifi()

        IconButton {
            visible: root.usable
            icon: "refresh"
            tonal: false
            onClicked: NetworkState.rescan()
        }
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.xl
        Layout.bottomMargin: Theme.spacing.xl
        visible: !root.usable
        icon: "signal_wifi_off"
        title: !NetworkState.wifiAvailable ? "No Wi-Fi adapter" : NetworkState.wifiBlockedByHardware ? "Wi-Fi is blocked" : "Wi-Fi is off"
        subtitle: !NetworkState.wifiAvailable ? "" : NetworkState.wifiBlockedByHardware ? "Check the hardware switch or airplane mode." : "Turn it on to see networks."
    }

    Card {
        Layout.fillWidth: true
        visible: root.usable && NetworkState.activeNetwork !== null
        implicitHeight: Theme.size.listRow + Theme.spacing.sm

        ListRow {
            anchors.fill: parent
            anchors.margins: Theme.spacing.xs
            clickable: false
            iconFill: 1
            icon: NetworkState.signalIcon(NetworkState.activeNetwork?.signalStrength ?? 0)
            title: NetworkState.activeNetwork?.name ?? ""
            subtitle: NetworkState.activeNetwork ? "Connected · " + NetworkState.securityName(NetworkState.activeNetwork) : ""

            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "Disconnect"
                onClicked: NetworkState.activeNetwork?.disconnect()
            }
        }
    }

    SectionHeader {
        visible: root.usable
        text: root.others.length > 0 ? "Available networks" : "Searching for networks…"
    }

    ScrollArea {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.usable

        Repeater {
            model: ScriptModel {
                values: root.others
            }

            WifiNetworkRow {
                required property var modelData

                width: parent.width
                network: modelData
            }
        }
    }
}
