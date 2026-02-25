{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

  configName = cfg.configName;

  # IMPORTANT:
  # We must create a REAL directory tree with REAL files (not symlinks).
  # Otherwise QML resolves imports relative to the canonical store file path
  # (e.g. /nix/store/...-shell.qml) and `import "components"` becomes /nix/store/components.
  quickshellConfigDir = pkgs.runCommand "quickshell-${configName}" { } ''
    set -eu
    mkdir -p "$out/components"

    # root
    cp -f ${./shell.qml} "$out/shell.qml"

    # components
    cp -f ${./components/Bar.qml} "$out/components/Bar.qml"
    cp -f ${./components/Dock.qml} "$out/components/Dock.qml"
    cp -f ${./components/GlassRect.qml} "$out/components/GlassRect.qml"
    cp -f ${./components/IconButton.qml} "$out/components/IconButton.qml"
    cp -f ${./components/WorkspaceSwitcher.qml} "$out/components/WorkspaceSwitcher.qml"
    cp -f ${./components/MprisMini.qml} "$out/components/MprisMini.qml"
    cp -f ${./components/BluetoothIndicator.qml} "$out/components/BluetoothIndicator.qml"
    cp -f ${./components/WifiIndicator.qml} "$out/components/WifiIndicator.qml"
    cp -f ${./components/Tray.qml} "$out/components/Tray.qml"
  '';
in
{
  options.programs.quickshellBarDock = {
    enable = lib.mkEnableOption "Quickshell bar + dock";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package to use.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Quickshell config name under ~/.config/quickshell/.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start Quickshell via systemd user service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.networkmanager pkgs.bluez pkgs.playerctl ];
      description = "Runtime tools; nmcli (wifi), bluez, playerctl optional.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraPackages;

    # Make absolutely sure Quickshell sees the config in a "valid config path"
    # and that the directory is an actual tree (not symlink farm).
    xdg.configFile."quickshell/${configName}".source = quickshellConfigDir;

    # Keep programs.quickshell enabled if you want its integration,
    # but the critical part is the directory above.
    programs.quickshell = {
      enable = true;
      package = cfg.package;
      activeConfig = configName;
      configs.${configName} = quickshellConfigDir;
    };

    # Your own unit (since you confirmed no quickshell unit exists via HM in your setup)
    systemd.user.services.quickshell = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Quickshell bar + dock";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/quickshell -c ${configName}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
