{ config, pkgs, lib, ... }:

{
  imports = [
    ./env.nix
    ./theme.nix
    ./rules.nix
    ./binds.nix

    ./liquid-glass.nix
    ./hyprland.nix

    ./waybar.nix
    ./rofi.nix
    ./notifications.nix
    ./hyprpaper.nix
    ./hyprlock.nix
    ./dock.nix
    ./ghostty.nix
  ];
}
