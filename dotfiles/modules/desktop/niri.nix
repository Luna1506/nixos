{ config, pkgs, lib, ... }:

{
  # niri als NixOS-Programm aktivieren
  programs.niri.enable = true; # NixOS option: programs.niri.enable :contentReference[oaicite:0]{index=0}

  # X11-Apps unter niri:
  # niri nutzt xwayland-satellite (rootless XWayland). Stelle sicher, dass es im PATH ist. :contentReference[oaicite:1]{index=1}
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  # Session-Variablen (wie bei Hyprland) – gelten dann für niri genauso
  environment.sessionVariables = {
    WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:0b:00.0-card";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Portals (Screensharing, Filepicker, etc.)
  # Für niri gibt es (Stand heute) kein spezielles "xdg-desktop-portal-niri" Paket wie hyprland.
  # Deshalb: xdg-desktop-portal + gtk als solide Standard-Kombi.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}

