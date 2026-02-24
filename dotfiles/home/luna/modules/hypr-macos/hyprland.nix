{ config, pkgs, lib, ... }:

let
  t = config.hyprMacos;
  binds = config.hyprMacos.binds or [ ];
  rules = config.hyprMacos.windowRules or [ ];
in
{
  wayland.windowManager.hyprland = {
    enable = true;

    # ✅ keine Plugins laden
    plugins = [ ];

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

        # ✅ Blur ist weiterhin decoration:blur:* (passt)
        blur = {
          enabled = true;
          size = t.blurSize;
          passes = t.blurPasses;

          ignore_opacity = true;
          new_optimizations = true;
          xray = true;

          noise = 0.02;
          contrast = 1.05;
          brightness = 1.0;
          vibrancy = 0.18;
          vibrancy_darkness = 0.0;
        };

        # ✅ Shadow ist jetzt decoration:shadow:*
        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          color = "rgba(00000055)";
          # optional:
          # ignore_window = true;
          # offset = "0 0";
          # scale = 1.0;
        };
      };

      # ✅ Layer rules: neue 0.53 Syntax
      layerrule = [
        "blur on, match:namespace ^(waybar)$"
        "ignore_alpha 0.0, match:namespace ^(waybar)$"

        "blur on, match:namespace ^(swaync-control-center)$"
        "blur on, match:namespace ^(swaync-notification-window)$"
        "ignore_alpha 0.0, match:namespace ^(swaync-control-center)$"
        "ignore_alpha 0.0, match:namespace ^(swaync-notification-window)$"

        "blur on, match:namespace ^(nwg-dock|nwg-dock-hyprland)$"
        "ignore_alpha 0.0, match:namespace ^(nwg-dock|nwg-dock-hyprland)$"
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

      # Falls du wirklich schon auf der neuen Window-Rules Syntax bist,
      # dann solltest du hier "windowrule" statt "windowrulev2" benutzen.
      # Ich lasse es erstmal wie du es hattest, aber das könnte der nächste Stolperstein sein.
      windowrulev2 = rules;
    };
  };
}
