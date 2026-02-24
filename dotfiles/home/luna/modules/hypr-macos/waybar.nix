{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 10;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "clock" = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 14px;
        font-family: sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(255,255,255,0.08);
        color: rgba(255,255,255,0.95);
      }

      #workspaces button {
        padding: 0 8px;
        margin: 6px 4px;
        background: rgba(255,255,255,0.08);
      }

      #workspaces button.active {
        background: rgba(255,255,255,0.18);
      }

      #clock, #pulseaudio, #network, #battery, #tray {
        margin: 6px 6px;
        padding: 0 10px;
        background: rgba(255,255,255,0.08);
      }
    '';
  };
}
