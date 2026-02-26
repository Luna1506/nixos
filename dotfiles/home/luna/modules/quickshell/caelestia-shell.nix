{ config, lib, pkgs, inputs ? null, ... }:

let
  cfg = config.programs.caelestiaShell;
  system = pkgs.stdenv.hostPlatform.system;

  # Deine vendorte Caelestia-QML Config im Repo:
  # ~/nixos/dotfiles/home/luna/modules/quickshell/caelestia-shell/...
  src = ./caelestia-shell;

  caelestiaFlake =
    if inputs == null || !(inputs ? caelestia-shell)
    then
      throw ''
        inputs.caelestia-shell is missing.

        Add in your top-level flake inputs:
          caelestia-shell.url = "path:./home/luna/modules/quickshell/caelestia-shell";

        And pass inputs into home-manager via extraSpecialArgs.
      ''
    else inputs.caelestia-shell;

  # Caelestia package (oft ist "with-cli" vollständiger, weil es extra Module/Services mitbringt)
  caelestiaPkg =
    if caelestiaFlake.packages.${system} ? with-cli
    then caelestiaFlake.packages.${system}.with-cli
    else caelestiaFlake.packages.${system}.default;

  # WICHTIG: Quickshell passend zum Caelestia-Flake pinnen (statt pkgs.quickshell = 0.2.1)
  pinnedQuickshell =
    if (caelestiaFlake ? inputs) && (caelestiaFlake.inputs ? quickshell)
    then caelestiaFlake.inputs.quickshell.packages.${system}.default
    else pkgs.quickshell;

  configName = "caelestia";

  qmlPaths = [
    "${caelestiaPkg}/lib/qt6/qml"
    "${caelestiaPkg}/lib/qt-6/qml"
    "${caelestiaPkg}/lib/qt6/imports"
    "${caelestiaPkg}/lib/qt-6/imports"
    # falls das package qml direkt irgendwo anders hinlegt:
    "${caelestiaPkg}/qml"
  ];

  pluginPaths = [
    "${caelestiaPkg}/lib/qt6/plugins"
    "${caelestiaPkg}/lib/qt-6/plugins"
    "${caelestiaPkg}/lib/plugins"
  ];

  join = lib.concatStringsSep ":";

in
{
  options.programs.caelestiaShell = {
    enable = lib.mkEnableOption "Caelestia Shell (Quickshell)";

    quickshellPackage = lib.mkOption {
      type = lib.types.package;
      default = pinnedQuickshell;
      description = "Quickshell package used to run Caelestia Shell.";
    };

    caelestiaPackage = lib.mkOption {
      type = lib.types.package;
      default = caelestiaPkg;
      description = "Caelestia shell package providing QML modules/plugins.";
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
    home.packages = [ cfg.quickshellPackage cfg.caelestiaPackage ] ++ cfg.extraPackages;

    # Quickshell config in ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/${configName}".source = src;

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";

        Environment = [
          "XDG_CONFIG_HOME=${config.xdg.configHome}"

          "QML_IMPORT_PATH=${join qmlPaths}"
          "QML2_IMPORT_PATH=${join qmlPaths}"

          "QT_PLUGIN_PATH=${join pluginPaths}"
        ];

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
