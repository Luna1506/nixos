{ config, lib, pkgs, ... }:

let
  cfg = config.programs.caelestiaShell;

  # vendored repo folder next to this module
  upstream = ./caelestia-shell;

  derivedSource = pkgs.runCommand "hm_caelestiashell" { } ''
        set -eu
        mkdir -p "$out"
        cp -R ${upstream}/. "$out/"

        # Create a proper QML module layout so `import Caelestia...` works AND
        # sibling types (e.g. BeatTracker.qml, CavaProvider.qml) resolve correctly.
        mkdir -p "$out/Caelestia" "$out/Caelestia/Services" "$out/Caelestia/Utils" "$out/Caelestia/Config"

        # Mirror dirs into module dirs (copy, not symlink, to keep it simple in store)
        if [ -d "$out/services" ]; then
          cp -R "$out/services/." "$out/Caelestia/Services/"
        fi
        if [ -d "$out/utils" ]; then
          cp -R "$out/utils/." "$out/Caelestia/Utils/"
        fi
        if [ -d "$out/config" ]; then
          cp -R "$out/config/." "$out/Caelestia/Config/"
        fi

        # --- qmldir: Caelestia (root)
        cat > "$out/Caelestia/qmldir" <<'EOF'
    module Caelestia

    # expose config types via the module
    Config 1.0 Config/Config.qml
    Appearance 1.0 Config/Appearance.qml
    AppearanceConfig 1.0 Config/AppearanceConfig.qml
    UserPaths 1.0 Config/UserPaths.qml
    EOF

        # --- qmldir: Caelestia.Services
        cat > "$out/Caelestia/Services/qmldir" <<'EOF'
    module Caelestia.Services

    # export entrypoints; siblings will resolve because they now live next to Audio.qml
    Audio 1.0 Audio.qml
    EOF

        # --- qmldir: Caelestia.Utils
        cat > "$out/Caelestia/Utils/qmldir" <<'EOF'
    module Caelestia.Utils

    Icons 1.0 Icons.qml
    Images 1.0 Images.qml
    NetworkConnection 1.0 NetworkConnection.qml
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

    # Deploy derived tree (with proper module dirs) to ~/.config/quickshell/caelestia
    xdg.configFile."quickshell/caelestia".source = derivedSource;

    xdg.configFile."caelestia/shell.json" = lib.mkIf (settingsJsonText != null) {
      text = settingsJsonText;
    };

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Caelestia Shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];

        # stop the "too quickly" spam while iterating
        StartLimitIntervalSec = 0;
      };

      Service = {
        Environment = [
          # Import root must contain the "Caelestia/" directory
          "QML_IMPORT_PATH=${xdgConfigPath}"
          "QML2_IMPORT_PATH=${xdgConfigPath}"
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
