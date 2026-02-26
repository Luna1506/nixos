{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  # Dein vendortes Repo
  src = ./caelestia-shell;

  # Baue das Caelestia Plugin/Package über deren Nix-Definition
  # (Das ist genau dafür da: QML Modul "Caelestia" + Services wie BeatTracker/CavaProvider)
  caelestiaPkg = pkgs.callPackage (src + "/nix/default.nix") { };

  xdgConfigPath = "${config.xdg.configHome}/quickshell/caelestia";
  shellQml = "${xdgConfigPath}/shell.qml";

  settingsJsonText =
    if cfg.settings == null
    then null
    else builtins.toJSON cfg.settings;

in
{
  options.programs.caelestiaShell = {
    enable = lib.mkEnableOption "Caelestia Quickshell (vendored repo + built plugin)";

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
    # Install Quickshell + Caelestia plugin package (+ optional extras)
    home.packages = [ cfg.quickshellPackage caelestiaPkg ] ++ cfg.extraPackages;

    # Deploy nur die Config/QML nach ~/.config/quickshell/caelestia
    # (Das Plugin kommt aus caelestiaPkg)
    xdg.configFile."quickshell/caelestia".source = src;

    # Optional overrides
    xdg.configFile."caelestia/shell.json" = lib.mkIf (settingsJsonText != null) {
      text = settingsJsonText;
    };

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        StartLimitIntervalSec = 0;
      };

      Service = {
        # Wichtig:
        # - QML_IMPORT_PATH muss das Plugin-QML sehen (Caelestia module)
        # - QT_PLUGIN_PATH hilft Qt, das native Plugin zu finden
        # Pfade können je nach Build leicht variieren, aber das ist der übliche Qt6-Layout.
        Environment = [
          "QML_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml:${xdgConfigPath}"
          "QML2_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml:${xdgConfigPath}"
          "QT_PLUGIN_PATH=${caelestiaPkg}/lib/qt-6/plugins"
        ];

        ExecStart = "${cfg.quickshellPackage}/bin/quickshell --path ${shellQml}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
