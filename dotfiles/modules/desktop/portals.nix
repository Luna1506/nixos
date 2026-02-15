{ pkgs, lib, ... }:

{
  # Portal Backends installieren/aktivieren
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];

    # WICHTIG: KEIN xdg.portal.config hier!
    # (sonst generiert NixOS zusätzlich eine portals.conf -> Duplicate default)
  };

  # Portals.conf systemweit erzwingen (einmalig, ohne Duplikate)
  environment.etc."xdg/xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gtk;kde;hyprland
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.OpenURI=gtk
    org.freedesktop.impl.portal.Settings=kde
    org.freedesktop.impl.portal.ScreenCast=kde;hyprland
    org.freedesktop.impl.portal.Screenshot=kde;hyprland
  '';

  # Optional aber hilfreich: Portal sieht /etc/xdg und findet .portal Backends sicher
  systemd.user.services.xdg-desktop-portal.environment = {
    XDG_CONFIG_DIRS = "/etc/xdg";
    XDG_DATA_DIRS = lib.makeSearchPath "share" [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];

    XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
  };
}
