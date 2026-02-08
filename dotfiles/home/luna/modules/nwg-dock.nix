{ config, pkgs, ... }:

let
  dockCss = ''
    window {
      background: rgba(18, 18, 22, 0.35);
      border-radius: 22px;
      background-clip: padding-box;
      border: 1px solid rgba(255, 255, 255, 0.14);
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.10);
      padding: 12px 18px;
    }

    button {
      margin: 0 8px;
      padding: 8px;
      border-radius: 14px;
      background: transparent;
      transition: background 120ms ease;
      color: rgba(255, 255, 255, 0.9);
    }

    button:hover {
      background: rgba(255, 255, 255, 0.10);
    }

    button:checked {
      background: rgba(255, 255, 255, 0.14);
    }
  '';

  # Launcher script: damit -c nur 1 "Befehl" ist (kein multi-arg parsing)
  launcherScript = ''
    #!/usr/bin/env bash
    exec ${pkgs.wofi}/bin/wofi --show drun
  '';

  # Autohide: startet/stoppt den Dock-Service je nach leerem Workspace
  autohideScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
    JQ=${pkgs.jq}/bin/jq
    SYSTEMCTL=${pkgs.systemd}/bin/systemctl
    SLEEP=${pkgs.coreutils}/bin/sleep

    while true; do
      WS=$($HYPRCTL activeworkspace -j | $JQ .id)
      COUNT=$($HYPRCTL clients -j | $JQ "[.[] | select(.workspace.id == $WS)] | length")

      if [ "$COUNT" -eq 0 ]; then
        $SYSTEMCTL --user start nwg-dock.service || true
      else
        $SYSTEMCTL --user stop nwg-dock.service || true
      fi

      $SLEEP 0.4
    done
  '';
in
{
  home.packages = with pkgs; [
    nwg-dock-hyprland
    wofi
    jq
  ];

  # CSS
  xdg.configFile."nwg-dock-hyprland/style.css".text = dockCss;

  # Appmenu SVG bleibt liegen (falls du später wieder damit spielst)
  xdg.configFile."nwg-dock-hyprland/icons/appmenu.svg".source =
    ./icons/appmenu.svg;

  # Launcher script
  home.file.".local/bin/wofi-drun-launcher.sh" = {
    executable = true;
    text = launcherScript;
  };

  # Autohide script
  home.file.".local/bin/nwg-dock-emptyws-autohide.sh" = {
    executable = true;
    text = autohideScript;
  };

  # Dock Service (WICHTIG: KEIN -r)
  systemd.user.services.nwg-dock = {
    Unit = {
      Description = "nwg-dock-hyprland (non-resident)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = ''
        ${pkgs.nwg-dock-hyprland}/bin/nwg-dock-hyprland \
          -p bottom \
          -a center \
          -i 56 \
          -ico %h/.config/nwg-dock-hyprland/icons/appmenu.svg \
          -c %h/.local/bin/wofi-drun-launcher.sh \
          -s style.css \
          -mb 20
      '';
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # Autohide Service (läuft dauerhaft)
  systemd.user.services.nwg-dock-emptyws-autohide = {
    Unit = {
      Description = "nwg-dock autohide (start/stop on empty workspace)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "%h/.local/bin/nwg-dock-emptyws-autohide.sh";
      Restart = "always";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
