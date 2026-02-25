{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

  fileText = path: builtins.readFile path;

  configName = cfg.configName;
in
{
  options.programs.quickshellBarDock = {
    enable = lib.mkEnableOption "Quickshell bar + dock (wrapper around HM programs.quickshell)";

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

    # IMPORTANT: use the official HM quickshell module to bundle config into one store dir
    programs.quickshell = {
      enable = true;
      package = cfg.package;

      activeConfig = configName;

      configs.${configName} = {
        "shell.qml" = fileText ./shell.qml;

        # Keep components in a real subdir; relative import works because HM bundles them together.
        "components/Bar.qml" = fileText ./components/Bar.qml;
        "components/Dock.qml" = fileText ./components/Dock.qml;
        "components/GlassRect.qml" = fileText ./components/GlassRect.qml;
        "components/IconButton.qml" = fileText ./components/IconButton.qml;
        "components/WorkspaceSwitcher.qml" = fileText ./components/WorkspaceSwitcher.qml;
        "components/MprisMini.qml" = fileText ./components/MprisMini.qml;
        "components/BluetoothIndicator.qml" = fileText ./components/BluetoothIndicator.qml;
        "components/WifiIndicator.qml" = fileText ./components/WifiIndicator.qml;
        "components/Tray.qml" = fileText ./components/Tray.qml;
      };

      # HM module provides the user unit; hook it to a reasonable target
      systemd.target = "graphical-session.target";
    };

    # If you want to disable autostart, we simply don't enable the unit via HM:
    # (Some HM versions do this via systemd.enable; if your HM doesn't support it,
    # you can just set autostart=false and manually run quickshell.)
    assertions = lib.optional (!cfg.autostart) {
      assertion = true;
      message = "autostart=false: start quickshell manually with `quickshell -c ${configName}`.";
    };
  };
}
