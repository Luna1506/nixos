import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
  id: root
  height: 22
  implicitWidth: Math.min(maxWidth, row.implicitWidth)
  property int maxWidth: 420

  property var player: null

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      let chosen = null
      for (let i = 0; i < Mpris.players.count; i++) {
        let p = Mpris.players.get(i)
        if (p && p.identity && (p.identity.toLowerCase().indexOf("spotify") >= 0)) {
          chosen = p
          break
        }
        if (!chosen && p) chosen = p
      }
      root.player = chosen
    }
  }

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: 8

    Text {
      Layout.alignment: Qt.AlignVCenter
      text: root.player ? (root.player.playbackState === MprisPlaybackState.Playing ? "▶" : "⏸") : "♪"
      color: "white"
      opacity: 0.9
      font.pixelSize: 12
    }

    Text {
      Layout.alignment: Qt.AlignVCenter
      text: root.player ? (root.player.title + " — " + root.player.artist) : "No player"
      color: "white"
      opacity: 0.9
      font.pixelSize: 12
      elide: Text.ElideRight
      maximumLineCount: 1
      width: root.maxWidth - 40
    }
  }
}
