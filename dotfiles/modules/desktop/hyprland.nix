{ config, pkgs, lib, ... }:

{
  # Hyprland als NixOS-Programm aktivieren
  programs.hyprland = {
    enable = true;
    # xwayland ist meistens sinnvoll für Legacy Apps
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

  # Optional, aber oft hilfreich (Portals für Screensharing/Themes etc.)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
    ];
  };
}

