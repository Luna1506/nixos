{ config, lib, username, monitor, ... }:

{
  # Ordner anlegen
  home.activation.createHyprWallpapersDir =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${config.home.homeDirectory}/.config/hypr/wallpapers"
    '';

  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = {
        monitor = monitor;
        path = "/home/${username}/.config/hypr/wallpaper/wallpaper1.jpg";
        fit_mode = "cover";
      };
      splash = false;
    };
  };
}

