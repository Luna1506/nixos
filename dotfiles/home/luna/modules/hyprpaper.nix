{ username, monitor, ... }:

{
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

