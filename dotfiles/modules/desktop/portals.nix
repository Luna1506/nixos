{ pkgs, lib, ... }:

{
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # Wichtig: In deinem NixOS-Modul erwartet xdg.portal.config pro Interface ein Attrset.
    config = {
      common = {
        default = [ "gtk" "hyprland" ];
      };

      "org.freedesktop.impl.portal.ScreenCast" = {
        default = "hyprland";
      };

      "org.freedesktop.impl.portal.Screenshot" = {
        default = "hyprland";
      };

      "org.freedesktop.impl.portal.FileChooser" = {
        default = "gtk";
      };

      "org.freedesktop.impl.portal.OpenURI" = {
        default = "gtk";
      };
    };
  };
}
