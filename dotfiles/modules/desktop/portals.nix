{ pkgs, lib, ... }:

{
  xdg.portal = {
    enable = true;

    # Nur die Backends, die unter Hyprland wirklich Sinn machen
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];

    # Saubere Portal-Zuweisung über NixOS (keine manuelle portals.conf)
    config = {
      common = {
        default = [ "gtk" "hyprland" ];
      };

      # Hyprland für Screensharing/Screenshot (wichtig für Discord/Webcord)
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];

      # GTK ist meist am kompatibelsten für Dialoge
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
    };
  };
}
