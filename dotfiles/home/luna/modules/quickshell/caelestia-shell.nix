{ config, lib, pkgs, inputs ? null, ... }:

let
  cfg = config.programs.caelestiaShell;

  # vendored config dir (qml etc.)
  src = ./caelestia-shell;

  system = pkgs.stdenv.hostPlatform.system;

  # Get the built package from the locked flake input
  caelestiaPkg =
    if inputs == null || !(inputs ? caelestia-shell)
    then
      throw ''
        inputs.caelestia-shell is missing.
        Add to your top-level flake inputs:
          caelestia-shell.url = "path:./home/luna/modules/quickshell/caelestia-shell";
        And pass inputs into home-manager extraSpecialArgs.
      ''
    else
      inputs.caelestia-shell.packages.${system}.default;

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
    home.packages = [ cfg.quickshellPackage caelestiaPkg ] ++ cfg.extraPackages;

    xdg.configFile."quickshell/caelestia".source = src;

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
        Environment = [
          "QML_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml:${xdgConfigPath}"
          "QML2_IMPORT_PATH=${caelestiaPkg}/lib/qt-6/qml:${xdgConfigPath}"
          "QT_PLUGIN_PATH=${caelestiaPkg}/lib/qt-6/plugins"
        ];

        ExecStart = "${cfg.quickshellPackage}/bin/quickshell --path ${shellQml}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
