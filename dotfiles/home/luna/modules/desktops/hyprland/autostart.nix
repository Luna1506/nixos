{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "hyprpaper"

      # Alle 3 Fenster direkt auf Workspace 1 (silent verhindert Geflacker)
      "[workspace 1 silent] ghostty --title main"
      "[workspace 1 silent] bash -lc 'sleep 0.2; exec ghostty --title matrix -e cmatrix'"
      "[workspace 1 silent] bash -lc 'sleep 0.4; exec ghostty --title cava -e cava'"
    ];
  };
}
