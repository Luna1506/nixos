{ config, pkgs, lib, ... }:

let
  t = config.hyprMacos;
  binds = config.hyprMacos.binds or [ ];
  rules = config.hyprMacos.windowRules or [ ];
  liquidGlass = config.hyprMacos.liquidGlassPlugin;
in
{
  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      liquidGlass
    ];

    settings = {
      monitor = [
        ",preferred,auto,1"
      ];

      exec-once = [
        "hyprpaper"
        "swaync"
        "waybar"
        "hypridle"
      ];

      input = {
        kb_layout = "de";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
        sensitivity = 0;
      };

      general = {
        gaps_in = t.gap;
        gaps_out = t.gap;
        border_size = t.border;

        layout = "dwindle";

        "col.active_border" = "rgba(ffffffff)";
        "col.inactive_border" = "rgba(88ffffff)";
      };

      decoration = {
        rounding = t.corner;

        drop_shadow = true;
        shadow_range = 18;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000055)";

        # Der Plugin-README empfiehlt: default blur aus, weil das Plugin "seinen" Glas-Blur macht. :contentReference[oaicite:4]{index=4}
        # Das kann aber Layer-Surfaces (Waybar/Dock) "weniger glassy" machen.
        # Deshalb: Blur AUS für windows, aber wir geben Layern gezielt Blur über layerrule.
        blur = {
          enabled = false;
        };
      };

      # Liquid Glass Plugin Config (aus README übernommen) :contentReference[oaicite:5]{index=5}
      plugin = {
        "liquid-glass" = {
          enabled = true;

          # "Maximum Apple Vibes" light version (tuned)
          blur_strength = 1.8;
          refraction_strength = 0.10;
          chromatic_aberration = 0.016;
          fresnel_strength = 0.55;
          specular_strength = 0.45;

          glass_opacity = 1.0;
          edge_thickness = 0.15;
        };
      };

      # Layer acrylic: Waybar / Dock / Notifications
      # Namespaces können je nach App minimal abweichen – die Patterns sind bewusst großzügig.
      layerrule = [
        "blur, ^(waybar)$"
        "ignorezero, ^(waybar)$"
        "blur, ^(swaync-control-center|swaync-notification-window)$"
        "ignorezero, ^(swaync-control-center|swaync-notification-window)$"
        "blur, ^(nwg-dock|nwg-dock-hyprland)$"
        "ignorezero, ^(nwg-dock|nwg-dock-hyprland)$"
      ];

      animations = {
        enabled = true;
        bezier = [
          "mac, 0.2, 0.9, 0.2, 1.0"
          "mac2, 0.16, 1, 0.3, 1"
        ];
        animation = [
          "windows, ${toString t.animSpeed}, 7, mac"
          "windowsIn, ${toString t.animSpeed}, 7, mac2, popin 80%"
          "windowsOut, ${toString t.animSpeed}, 6, mac"
          "border, ${toString t.animSpeed}, 8, mac"
          "fade, ${toString t.animSpeed}, 8, mac"
          "workspaces, ${toString t.animSpeed}, 6, mac, slide"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
      };

      bind = binds;
      windowrulev2 = rules;
    };
  };
}
