{ config, lib, pkgs, inputs ? null, ... }:

let
  cfg = config.programs.caelestiaShell;

  system = pkgs.stdenv.hostPlatform.system;

  # Your vendored Caelestia shell repo (qml, assets, etc.)
  src = ./caelestia-shell;

  # Locked flake input required (you already added it in flake.lock)
  caelestiaFlake =
    if inputs == null || !(inputs ? caelestia-shell)
    then
      throw ''
        inputs.caelestia-shell is missing.
        Add to your top-level flake inputs:
          caelestia-shell.url = "path:./home/luna/modules/quickshell/caelestia-shell";
        And pass inputs into home-manager extraSpecialArgs.
      ''
    else inputs.caelestia-shell;

  # Caelestia package (includes plugin + qml module installation)
  caelestiaPkg = caelestiaFlake.packages.${system}.default;

  # IMPORTANT: use the quickshell that Caelestia flake pins (usually master)
  pinnedQuickshell =
    if (caelestiaFlake ? inputs) && (caelestiaFlake.inputs ? quickshell)
    then caelestiaFlake.inputs.quickshell.packages.${system}.default
    else pkgs.quickshell;

  # We want quickshell to load this config by name via XDG paths:
  # ~/.config/quickshell/caelestia/shell.qml
  configName = "caelestia";
  configDir = "${config.xdg.configHome}/quickshell/${configName}";

in
{
  options.programs.caelestiaShell = {
    enable = lib.mkEnableOption "Caelestia Shell (Quickshell)";

    # If you want to override quickshell manually you can,
    # but defaulting to the pinned one avoids the mismatch you currently see.
    quickshellPackage = lib.mkOption {
      type = lib.types.package;
      default = pinnedQuickshell;
      description = "Quickshell package used to run Caelestia Shell.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.quickshellPackage caelestiaPkg ] ++ cfg.extraPackages;

    # Put the config into ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/${configName}".source = src;

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";

        # Ensure quickshell sees the config by name, and Caelestia QML module is found
        Environment = [
          "XDG_CONFIG_HOME=${config.xdg.configHome}"

          # Caelestia plugin QML module path (this is where 'import Caelestia' comes from)
          "QML_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml"
          "QML2_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml"

          # Qt plugins (sometimes needed for imageformats, etc.)
          "QT_PLUGIN_PATH=${caelestiaPkg}/lib/qt-6/plugins"
        ];

        # Load config by name (uses ~/.config/quickshell/caelestia)
        ExecStart = "${cfg.quickshellPackage}/bin/quickshell -c ${configName}";

        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
