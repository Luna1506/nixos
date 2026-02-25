{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBarDock;

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

    # Deploy config directory as a single bundled store dir -> HM links it into ~/.config/quickshell/<name>
    programs.quickshell = {
      enable = true;
      package = cfg.package;
      activeConfig = configName;
      configs.${configName} = quickshellConfigDir;
    };

    # Re-add our own unit (since HM one doesn’t exist in your setup)
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
