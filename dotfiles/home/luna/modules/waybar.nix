{ pkgs, config, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 6;

        modules-left = [ "hyprland/workspaces" ];

        modules-right = [
          "wireplumber"
          "network"
          "bluetooth"
          "clock"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          all-outputs = true;
          format = "{name}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        wireplumber = {
          format = "  {volume}%";
          format-muted = " muted";
          on-click = "pavucontrol";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "{ipaddr}";
          format-disconnected = "  offline";
          tooltip = true;
          on-click = "sh -lc 'command -v nm-connection-editor >/dev/null && nm-connection-editor || nmtui'";
        };

        bluetooth = {
          format = "";
          format-off = " off";
          format-disabled = " off";
          tooltip = true;
          on-click = "sh -lc 'command -v blueman-manager >/dev/null && blueman-manager || bluetoothctl'";
        };

        clock = {
          format = "{:%a %d.%m · %H:%M}";
          tooltip-format = "{:%A, %d. %B %Y}";
        };

        "custom/power" = {
          format = "";
          tooltip = true;
          tooltip-format = "Power";
          on-click = "wlogout";
        };
      };
    };

    style = ''
          * {
            border: none;
            border-radius: 0;
            min-height: 0;
            margin: 0;
            padding: 0;
            font-family: "JetBrainsMono", "Noto Sans", sans-serif;
            font-size: 12px;
          }

          window#waybar {
            background: transparent;
            color: #eaeaea;
          }

          /* Pills (Acrylic / Frosted Glass) */
          #workspaces,
          #clock,
          #wireplumber,
          #network,
          #bluetooth,
          #custom-power {
      	margin: 6px 4px;
      	padding: 0 10px;

            /* Frosted background */
            background: rgba(255, 255, 255, 0.06);

            /* Acrylic blur */
            -gtk-icon-effect: none;
            backdrop-filter: blur(14px);
            -gtk-backdrop-filter: blur(14px);

            /* A bit of “acrylic edge” */
            border: 1px solid rgba(255, 255, 255, 0.10);
            box-shadow: 0 6px 18px rgba(0, 0, 0, 0.22);

            border-radius: 10px;
          }
          /* Nerd Fonts für alle Icons */
          #wireplumber,
          #network,
          #bluetooth,
          #custom-power {
            font-family: "JetBrainsMono Nerd Font",
                         "JetBrainsMono NF",
                         "Symbols Nerd Font",
                         "Noto Sans Symbols",
                         sans-serif;
          }

          /* Bluetooth: symmetrisch */
          #bluetooth {
            min-width: 34px;
            padding-left: 12px;
            padding-right: 12px;
          }

          #custom-power {
            min-width: 34px;
            padding-left: 12px;
            padding-right: 12px;
            font-weight: 700;
          }

          #bluetooth label,
          #custom-power label {
            margin: 0;
            padding: 0;
          }

          #wireplumber:hover,
          #network:hover,
          #bluetooth:hover,
          #custom-power:hover {
            background: rgba(255, 255, 255, 0.12);
            color: #ffffff;
          }

          /* Workspaces */
          #workspaces {
            padding: 0 6px;
          }

          #workspaces button {
            padding: 2px 8px;
            margin: 4px 3px;
            border-radius: 8px;
            background: transparent;
            color: #bdbdbd;
            transition: background 120ms ease, color 120ms ease;
          }

          #workspaces button.active {
            background: rgba(255, 255, 255, 0.14);
            color: #ffffff;
          }

          #workspaces button:hover {
            background: rgba(255, 255, 255, 0.10);
            color: #ffffff;
          }

          #workspaces button.urgent {
            background: rgba(255, 80, 80, 0.18);
            color: #ffffff;
          }

          #workspaces button.empty {
            color: rgba(255, 255, 255, 0.35);
          }

          /* States */
          #wireplumber.muted,
          #network.disconnected,
          #bluetooth.off,
          #bluetooth.disabled {
            color: rgba(255, 255, 255, 0.45);
          }

          tooltip {
            background: rgba(10, 10, 10, 0.90);
            color: #eaeaea;
            border-radius: 10px;
            padding: 8px 10px;
          }
    '';
  };

  home.file.".config/hypr/scripts/waybar-toggle.sh" = {
    source = ./scripts/waybar-toggle.sh;
    executable = true;
  };
}

