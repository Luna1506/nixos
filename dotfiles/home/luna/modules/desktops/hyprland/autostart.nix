{ ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "hyprctl dispatch workspace 1"

        # 1) links groß
        "ghostty --title main"

        # 2) rechts oben
        "ghostty --title matrix -e bash -lc 'cmatrix'"

        # 3) rechts unten
        "ghostty --title cava -e bash -lc 'cava'"

        "hyprpaper"
      ];
    };

    # Wichtig: neue Windowrules sind Block-Syntax -> am einfachsten via extraConfig
    extraConfig = ''
      windowrule {
        name = ws-main
        workspace = 1
        match:title = ^(main)$
      }

      windowrule {
        name = ws-matrix
        workspace = 1
        match:title = ^(matrix)$
      }

      windowrule {
        name = ws-cava
        workspace = 1
        match:title = ^(cava)$
      }
    '';
  };
}
