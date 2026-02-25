{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellOverview;

  # Pin the repo
  src = pkgs.fetchFromGitHub {
    owner = "Shanu-Kumawat";
    repo = "quickshell-overview";
    rev = cfg.rev;
    sha256 = cfg.sha256;
  };

  # Copy into a real directory (NOT symlinks) so relative QML imports work reliably
  overviewDir = pkgs.runCommand "quickshell-overview" { } ''
    set -eu
    mkdir -p "$out"
    cp -a ${src}/. "$out/"
  '';
in
{
  options.programs.quickshellOverview = {
    enable = lib.mkEnableOption "Quickshell Overview (Hyprland workspace overview)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package to use.";
    };

    # Pick a commit and hash once, then pin it.
    rev = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git revision (commit hash recommended) for quickshell-overview.";
    };

    sha256 = lib.mkOption {
      type = lib.types.str;
      default = lib.fakeSha256;
      description = "sha256 for fetchFromGitHub (use lib.fakeSha256 once, then replace).";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Autostart overview config via systemd user service.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.qt6.qtwayland
    ];

    # Put the repo at ~/.config/quickshell/overview
    xdg.configFile."quickshell/overview".source = overviewDir;

    # Autostart: `qs -c overview`
    systemd.user.services.quickshell-overview = lib.mkIf cfg.autostart {
      Unit = {
        Description = "Quickshell Overview";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/qs -c overview";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
