{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # optional: sicherstellen, dass du auf WS1 bist
      "hyprctl dispatch workspace 1"

      # links groß (erstes Fenster)
      "ghostty --title main"

      # rechts oben (zweites Fenster)
      "ghostty --title matrix -e cmatrix"

      # rechts unten (drittes Fenster)
      "ghostty --title cava -e cava"

      # wallpaper
      "hyprpaper"
    ];

    # Neue Window-Rule Syntax (windowrule = match:... , effect ...)
    windowrule = [
      "match:title ^(main)$, workspace 1"
      "match:title ^(matrix)$, workspace 1"
      "match:title ^(cava)$, workspace 1"
    ];
  };
}
