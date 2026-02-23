{ ... }:
{
  wayland.windowManager.hyprland.settings = {

    exec-once = [
      # Workspace 1 aktivieren
      "hyprctl dispatch workspace 1"

      # Hauptterminal (links groß)
      "ghostty --title main"

      # Rechts oben
      "ghostty --title matrix -e cmatrix"

      # Rechts unten
      "ghostty --title cava -e cava"

      # Hintergrund
      "hyprpaper"
    ];

    windowrulev2 = [
      "workspace 1, title:^(main)$"
      "workspace 1, title:^(matrix)$"
      "workspace 1, title:^(cava)$"
    ];
  };
}
