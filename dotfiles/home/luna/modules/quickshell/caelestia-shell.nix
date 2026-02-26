{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  # vendored repo directory (has its own flake.nix)
  src = ./caelestia-shell;

  system = pkgs.stdenv.hostPlatform.system;

  # IMPORTANT: Use a path-based flake reference
  caelestiaFlake = builtins.getFlake ("path:" + toString src);

  # pick a package from the flake outputs
  pkgsOut = caelestiaFlake.packages.${system} or { };

  caelestiaPkg =
    if pkgsOut ? default then pkgsOut.default
    else if pkgsOut ? caelestia-shell then pkgsOut."caelestia-shell"
    else if pkgsOut ? shell then pkgsOut.shell
    else
      throw ''
        Could not find a suitable package in caelestia-shell flake outputs.
        Try: (cd ${toString src}; nix flake show)
        Then pick one of: packages.${system}.default / packages.${system}.<name>
      '';

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
    home.packages = [ cfg.quickshellPackage caelestiaPkg ] ++ cfg.extraPackages;

    # Deploy config/QML tree
    xdg.configFile."quickshell/caelestia".source = src;

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
