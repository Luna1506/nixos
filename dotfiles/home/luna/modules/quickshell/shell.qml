import QtQuick
import Quickshell

import "components" as C

Item {
  C.Sidebar {
    id: sidebar
    onToggleTopPopup: topPopup.visible = !topPopup.visible
    onRequestTopTab: (idx) => {
      topPopup.visible = true
      topPopup.activeTab = idx
    }
  }

  C.TopPopup {
    id: topPopup
    visible: false
    onCloseRequested: visible = false
  }
}
