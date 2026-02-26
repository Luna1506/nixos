{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.caelestiaShell;

  system = pkgs.stdenv.hostPlatform.system;

  # Du hast das Flake-Input ja schon in deiner flake.lock/flake.nix drin:
  # inputs.caelestia-shell = { url = "path:./home/luna/modules/quickshell/caelestia-shell"; ... };
  caelestiaFlake = inputs.caelestia-shell;

  # Default Paket aus dem Caelestia-Shell flake
  shellPkgDefault = caelestiaFlake.packages.${system}.default;

  # Das Plugin hängt bei upstream als passthru.plugin dran (siehe nix/default.nix im repo).
  pluginPkg =
    if shellPkgDefault ? plugin then shellPkgDefault.plugin else null;

  # Mögliche Pfade (je nach qt6 layout in deinem Build)
  mkQmlPath = p: [
    "${p}/lib/qt-6/qml"
    "${p}/lib/qt6/qml"
    "${p}/lib/qt-6/qml/${""}" # harmless, nur damit man in logs sieht was gesetzt ist
  ];

  mkQtPluginPath = p: [
    "${p}/lib/qt-6/plugins"
    "${p}/lib/qt6/plugins"
  ];

  qmlImportPath =
    lib.concatStringsSep ":"
      (lib.unique (
        (mkQmlPath shellPkgDefault)
        ++ lib.optionals (pluginPkg != null) (mkQmlPath pluginPkg)
      ));

  qtPluginPath =
    lib.concatStringsSep ":"
      (lib.unique (
        (mkQtPluginPath shellPkgDefault)
        ++ lib.optionals (pluginPkg != null) (mkQtPluginPath pluginPkg)
      ));

in
{
  options.programs.caelestiaShell = {
    enable = lib.mkEnableOption "Caelestia Shell (Quickshell config + plugin paths)";

    # Deine lokale Config im Repo (die du “dreist reingepackt” hast)
    configDir = lib.mkOption {
      type = lib.types.path;
      default = ./caelestia-shell;
      description = "Path to the caelestia-shell QML config directory (copied to ~/.config/quickshell/caelestia).";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = shellPkgDefault;
      description = "Caelestia shell package providing the QML plugin modules.";
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = config.wayland.systemd.target or "graphical-session.target";
      description = "Systemd target that starts the service.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra environment variables for the systemd user service.";
      example = [ "QT_QPA_PLATFORMTHEME=qt6ct" ];
    };
  };

  config = lib.mkIf cfg.enable {

    # Deine QML Config in den XDG config Pfad deployen:
    xdg.configFile."quickshell/caelestia".source = cfg.configDir;

    # Optional: falls du Assets brauchst und QuickShell sie relativ erwartet
    # xdg.configFile."quickshell/caelestia".recursive = true; # source ist directory => recursive implizit

    systemd.user.services.caelestia-shell = {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        After = [ cfg.systemdTarget ];
        PartOf = [ cfg.systemdTarget ];

        # StartLimit gehört hierhin, nicht in [Service]
        StartLimitIntervalSec = 30;
        StartLimitBurst = 5;
      };

      Service = {
        Type = "simple";

        # Wichtig: wir starten quickshell direkt auf deine Config (-c caelestia)
        ExecStart = "${pkgs.quickshell}/bin/quickshell -c caelestia";

        Restart = "on-failure";
        RestartSec = 1;

        Environment =
          [
            "XDG_CONFIG_HOME=${config.xdg.configHome}"
            # DAS ist der eigentliche Fix: QML muss das Caelestia Plugin finden
            "QML_IMPORT_PATH=${qmlImportPath}"
            "QML2_IMPORT_PATH=${qmlImportPath}"
            "QT_PLUGIN_PATH=${qtPluginPath}"
            # Wayland erzwingen (kann helfen)
            "QT_QPA_PLATFORM=wayland"
          ]
          ++ cfg.extraEnvironment;
      };

      Install = {
        WantedBy = [ cfg.systemdTarget ];
      };
    };

    home.packages = [
      cfg.package
      pkgs.quickshell
    ];
  };
}
