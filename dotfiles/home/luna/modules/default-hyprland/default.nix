{ inputs, config, pkgs, zoom, ... }:
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
    ./ghostty.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    #./nwg-dock.nix
    ./starship.nix
    ./theme.nix
    #./waybar.nix
    ./wofi.nix
  ];

  wayland.windowManager.hyprland = {
      enable = true;
      plugins = [
        inputs.liquid-glass.packages.${pkgs.system}.default
      ];
    };
}

