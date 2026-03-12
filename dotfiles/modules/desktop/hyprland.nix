{ config, pkgs, lib, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };
  # WICHTIG: diese Variablen müssen beim Start der Session gesetzt sein
  environment.sessionVariables = {
    # Damit Hyprland die richtige DRM-Karte nimmt (card1 statt simpledrm/card0)
    WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:0b:00.0-card";

    # NVIDIA + wlroots Klassiker
    WLR_NO_HARDWARE_CURSORS = "1";

    # Electron/Chromium Apps auf Wayland
    NIXOS_OZONE_WL = "1";
  };
}

