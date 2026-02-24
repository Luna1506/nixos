{ config, pkgs, zoom, ... }:
{
  imports = [
    ./vars.nix
    ./monitors.nix
    ./env.nix
    ./autostart.nix
    ./look.nix
    ./input.nix
    ./binds.nix
    ./rules.nix
  ];

  wayland.windowManager.hyprland.enable = true;
}

