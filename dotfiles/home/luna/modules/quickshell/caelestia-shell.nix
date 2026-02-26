{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  localSource = ./caelestia-shell;
  shellQml = "${localSource}/shell.qml";

  settingsJsonText =
    if cfg.settings == null
    then null
    else builtins.toJSON cfg.settings;

in
{
  options.programs.caelestiaShell = {
    enable = lib.mkEnableOption "Caelestia Quickshell (local vendored copy)";

    quickshellPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {

    home.packages =
      [ cfg.quickshellPackage ]
      ++ cfg.extraPackages;

    # Deploy entire vendored shell into ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/caelestia".source = localSource;

    # Optional user settings override
    xdg.configFile."caelestia/shell.json" = lib.mkIf (settingsJsonText != null) {
      text = settingsJsonText;
    };

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.quickshellPackage}/bin/quicksshell --path ${shellQml}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
