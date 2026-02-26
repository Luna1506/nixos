{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  # vendored repo folder next to this module
  localSource = ./caelestia-shell;

  # use the deployed config under XDG, not the raw repo path
  xdgConfigPath = "${config.xdg.configHome}/quickshell/caelestia";
  shellQml = "${xdgConfigPath}/shell.qml";

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
      description = "Quickshell package used to run the shell.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = "Written to ~/.config/caelestia/shell.json as JSON.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.quickshellPackage ] ++ cfg.extraPackages;

    # deploy vendored repo to ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/caelestia".source = localSource;

    # optional overrides file
    xdg.configFile."caelestia/shell.json" = lib.mkIf (settingsJsonText != null) {
      text = settingsJsonText;
    };

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        # Make Qt find "import Caelestia" inside your deployed config tree.
        # Also include common subdirs used by Caelestia.
        Environment = [
          "QML_IMPORT_PATH=${xdgConfigPath}:${xdgConfigPath}/config:${xdgConfigPath}/components:${xdgConfigPath}/modules"
          "QML2_IMPORT_PATH=${xdgConfigPath}:${xdgConfigPath}/config:${xdgConfigPath}/components:${xdgConfigPath}/modules"
        ];

        # correct binary name: quickshell
        ExecStart = "${cfg.quickshellPackage}/bin/quickshell --path ${shellQml}";

        Restart = "on-failure";
        RestartSec = 1;

        # avoid "start request repeated too quickly" while debugging
        StartLimitIntervalSec = 0;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
