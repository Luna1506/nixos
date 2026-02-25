{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;
  configName = cfg.configName;

  quickshellConfigDir = pkgs.runCommand "quickshell-${configName}" { } ''
    set -eu
    mkdir -p "$out/components"

    cp -f ${./shell.qml} "$out/shell.qml"
    cp -f ${./components/Sidebar.qml} "$out/components/Sidebar.qml"
  '';
in
{
  options.programs.quickshellBarDock = {
    enable = lib.mkEnableOption "Quickshell sidebar";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "default";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.rofi pkgs.hyprlock pkgs.networkmanager pkgs.bluez pkgs.hyprland ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraPackages;

    xdg.configFile."quickshell/${configName}".source = quickshellConfigDir;

    programs.quickshell = {
      enable = true;
      package = cfg.package;
      activeConfig = configName;
      configs.${configName} = quickshellConfigDir;
    };

    systemd.user.services.quickshell-sidebar = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Quickshell Sidebar";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/quickshell -c ${configName}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
