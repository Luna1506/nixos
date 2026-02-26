{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  # vendored repo folder next to this module
  upstream = ./caelestia-shell;

  # Build a derived source tree that also provides QML modules:
  #   import Caelestia
  #   import Caelestia.Services
  #   import Caelestia.Utils
  derivedSource = pkgs.runCommand "hm_caelestiashell" { } ''
        set -eu
        mkdir -p "$out"
        cp -R ${upstream}/. "$out/"

        # --------------------------
        # Module: Caelestia
        # --------------------------
        mkdir -p "$out/Caelestia"
        cat > "$out/Caelestia/qmldir" <<'EOF'
    module Caelestia

    # Core config/types (based on what your error chain references)
    Config 1.0 ../config/Config.qml
    Appearance 1.0 ../config/Appearance.qml
    AppearanceConfig 1.0 ../config/AppearanceConfig.qml
    UserPaths 1.0 ../config/UserPaths.qml
    EOF

        # --------------------------
        # Module: Caelestia.Services
        # --------------------------
        mkdir -p "$out/Caelestia/Services"
        cat > "$out/Caelestia/Services/qmldir" <<'EOF'
    module Caelestia.Services

    Audio 1.0 ../../services/Audio.qml
    EOF

        # --------------------------
        # Module: Caelestia.Utils
        # --------------------------
        mkdir -p "$out/Caelestia/Utils"
        cat > "$out/Caelestia/Utils/qmldir" <<'EOF'
    module Caelestia.Utils

    Icons 1.0 ../../utils/Icons.qml
    Images 1.0 ../../utils/Images.qml
    NetworkConnection 1.0 ../../utils/NetworkConnection.qml
    EOF
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

    # Deploy derived tree (with Caelestia/* modules) to ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/caelestia".source = derivedSource;

    xdg.configFile."caelestia/shell.json" = lib.mkIf (settingsJsonText != null) {
      text = settingsJsonText;
    };

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];

        # belongs in [Unit], not [Service]
        StartLimitIntervalSec = 0;
      };

      Service = {
        Environment = [
          # QML import roots – must include the folder that contains "Caelestia/"
          "QML_IMPORT_PATH=${xdgConfigPath}:${xdgConfigPath}/modules:${xdgConfigPath}/components:${xdgConfigPath}/config"
          "QML2_IMPORT_PATH=${xdgConfigPath}:${xdgConfigPath}/modules:${xdgConfigPath}/components:${xdgConfigPath}/config"
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
