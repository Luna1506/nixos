{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

  configName = cfg.configName;

  # REAL directory tree with REAL files (not symlinks)
  quickshellConfigDir = pkgs.runCommand "quickshell-${configName}" { } ''
    set -eu
    mkdir -p "$out/components"

    cp -f ${./shell.qml} "$out/shell.qml"

    # Only what Sidebar needs:
    cp -f ${./components/Sidebar.qml} "$out/components/Sidebar.qml"
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
      description = "Start Quickshell via systemd user service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.rofi pkgs.hyprlock ];
      description = "Runtime tools used by the sidebar (rofi, hyprlock, etc).";
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

    systemd.user.services.quickshell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Quickshell sidebar";
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
