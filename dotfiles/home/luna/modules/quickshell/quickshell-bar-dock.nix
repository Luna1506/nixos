{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshell;

  fileText = path: builtins.readFile path;

  # Config folder name under ~/.config/quickshell/<name>
  configName = cfg.configName;
  targetDir = ".config/quickshell/${configName}";
in
{
  options.programs.quickshell = {
    enable = lib.mkEnableOption "Quickshell bar + dock";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package to use.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Quickshell config directory name under ~/.config/quickshell/.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start Quickshell via systemd user service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.networkmanager pkgs.bluez pkgs.playerctl ];
      description = "Extra runtime tools; nmcli (wifi), bluez, playerctl optional.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraPackages;

    # Deploy Quickshell config files declaratively
    home.file."${targetDir}/shell.qml".text =
      fileText ./shell.qml;

    home.file."${targetDir}/components/Bar.qml".text =
      fileText ./components/Bar.qml;

    home.file."${targetDir}/components/Dock.qml".text =
      fileText ./components/Dock.qml;

    home.file."${targetDir}/components/GlassRect.qml".text =
      fileText ./components/GlassRect.qml;

    home.file."${targetDir}/components/IconButton.qml".text =
      fileText ./components/IconButton.qml;

    home.file."${targetDir}/components/WorkspaceSwitcher.qml".text =
      fileText ./components/WorkspaceSwitcher.qml;

    home.file."${targetDir}/components/MprisMini.qml".text =
      fileText ./components/MprisMini.qml;

    home.file."${targetDir}/components/BluetoothIndicator.qml".text =
      fileText ./components/BluetoothIndicator.qml;

    home.file."${targetDir}/components/WifiIndicator.qml".text =
      fileText ./components/WifiIndicator.qml;

    home.file."${targetDir}/components/Tray.qml".text =
      fileText ./components/Tray.qml;

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
