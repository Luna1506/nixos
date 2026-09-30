{ inputs, config, pkgs, ... }:
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
    ./waybar.nix
    ./wofi.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland + Portal kommen aus dem NixOS-Modul (programs.hyprland).
    # Sonst setzt Home-Manager NIX_XDG_DESKTOP_PORTAL_DIR auf das User-Profil,
    # das nur hyprland.portal enthält -> gtk-Portal & System-Config werden ignoriert.
    package = null;
    portalPackage = null;
    # hyprland.lua statt hyprland.conf (hyprlang fällt mit Hyprland 0.57 weg)
    configType = "lua";
  };

}

