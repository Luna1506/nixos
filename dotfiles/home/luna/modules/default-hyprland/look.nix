{ lib, ... }:
let
  bezier = name: x1: y1: x2: y2: {
    _args = [ name { type = "bezier"; points = [ [ x1 y1 ] [ x2 y2 ] ]; } ];
  };

  animation = leaf: speed: curve: style:
    { inherit leaf speed; enabled = true; bezier = curve; }
    // lib.optionalAttrs (style != null) { inherit style; };
in
{
  wayland.windowManager.hyprland.settings = {
    config = {
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
        col.active_border = "rgba(ffffffff)";
        resize_on_border = true;
        allow_tearing = false;
      };

      decoration = {
        rounding = 25;
        rounding_power = 2.0;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 20;
        };

        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = false;
        };
      };

      animations.enabled = true;

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 1;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        focus_on_activate = true;
        middle_click_paste = false;
      };
    };

    # Blur für alle Layer (inkl. waybar)
    layer_rule = [
      { match.namespace = "^(.*)$"; blur = true; ignore_alpha = 0.3; }
    ];

    curve = [
      (bezier "easeOutQuint" 0.23 1 0.32 1)
      (bezier "easeInOutCubic" 0.65 0 0.35 1)
      (bezier "linear" 0 0 1 1)
      (bezier "almostLinear" 0.5 0.5 0.75 1)
      (bezier "quick" 0.15 0 0.1 1)
      (bezier "slideEaseOut" 0 0.6 0.2 1)
    ];

    animation = [
      (animation "global" 10 "default" null)
      (animation "border" 5.39 "easeOutQuint" null)
      (animation "windows" 4.79 "easeOutQuint" null)
      (animation "windowsIn" 4.1 "easeOutQuint" "popin 87%")
      (animation "windowsOut" 1.49 "linear" "popin 87%")
      (animation "fadeIn" 1.73 "almostLinear" null)
      (animation "fadeOut" 1.46 "almostLinear" null)
      (animation "fade" 3.03 "quick" null)
      (animation "layers" 3.81 "easeOutQuint" null)
      (animation "layersIn" 4 "easeOutQuint" "fade")
      (animation "layersOut" 1.5 "linear" "fade")
      (animation "fadeLayersIn" 1.79 "almostLinear" null)
      (animation "fadeLayersOut" 1.39 "almostLinear" null)
      (animation "workspaces" 1.94 "easeInOutCubic" "slide")
      (animation "workspacesIn" 1.21 "easeInOutCubic" "slide")
      (animation "workspacesOut" 1.94 "easeInOutCubic" "slide")
      (animation "zoomFactor" 7 "quick" null)
    ];
  };
}
