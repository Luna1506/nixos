{ ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = {
        monitor = "eDP-1";
        path = "/home/luna/.config/hypr/wallpaper/wallpaper1.jpg";
        fit_mode = "cover";
      };
      splash = false;
    };
  };
}

