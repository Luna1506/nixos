{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

  # Build a single config dir in the store containing all QML files
  configName = cfg.configName;

  quickshellConfigDir =
    pkgs.linkFarm "quickshell-${configName}" [
      { name = "shell.qml"; path = ./shell.qml; }

      { name = "components/Bar.qml"; path = ./components/Bar.qml; }
      { name = "components/Dock.qml"; path = ./components/Dock.qml; }
      { name = "components/GlassRect.qml"; path = ./components/GlassRect.qml; }
      { name = "components/IconButton.qml"; path = ./components/IconButton.qml; }
      { name = "components/WorkspaceSwitcher.qml"; path = ./components/WorkspaceSwitcher.qml; }
      { name = "components/MprisMini.qml"; path = ./components/MprisMini.qml; }
      { name = "components/BluetoothIndicator.qml"; path = ./components/BluetoothIndicator.qml; }
      { name = "components/WifiIndicator.qml"; path = ./components/WifiIndicator.qml; }
      { name = "components/Tray.qml"; path = ./components/Tray.qml; }
    ];
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
      description = "Quickshell config name (directory under ~/.config/quickshell/).";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start Quickshell via the Home Manager quickshell systemd user unit.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.networkmanager pkgs.bluez pkgs.playerctl ];
      description = "Runtime tools; nmcli (wifi), bluez, playerctl optional.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.extraPackages;

    programs.quickshell = {
      enable = true;
      package = cfg.package;

      activeConfig = configName;

      # IMPORTANT: configs.<name> is an ABSOLUTE PATH to a directory
      configs.${configName} = quickshellConfigDir;

      systemd.target = "graphical-session.target";
    };

    # Optional: if you want to “disable autostart” later, we’d override systemd
    assertions = lib.optional (!cfg.autostart) {
      assertion = true;
      message = "autostart=false: start quickshell manually with `quickshell -c ${configName}`.";
    };
  };
}
