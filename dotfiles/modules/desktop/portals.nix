{ pkgs, lib, ... }:

{
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # Die Keys von xdg.portal.config sind Desktop-Namen (-> <name>-portals.conf),
    # NICHT Interface-Namen. Die Interfaces gehören als Attribute in den Desktop-Block.
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };

      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
      };
    };
  };
}
