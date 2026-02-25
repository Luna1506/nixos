{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

  configName = cfg.configName;

  quickshellConfigDir = pkgs.runCommand "quickshell-${configName}" { } ''
    set -eu
    mkdir -p "$out/components"

    cp -f ${./shell.qml} "$out/shell.qml"

    # only sidebar bits
    cp -f ${./components/SideBar.qml} "$out/components/SideBar.qml"
    cp -f ${./components/GlassRect.qml} "$out/components/GlassRect.qml"
  '';
in
{
  options.programs.quickshellBarDock = {
    enable = lib.mkEnableOption "Quickshell sidebar";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package to use.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Quickshell config name under ~/.config/quickshell/.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start sidebar via systemd user service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.rofi pkgs.hyprlock pkgs.hyprland ];
      description = "Runtime tools used by the sidebar.";
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

    # IMPORTANT: unique unit name
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
