{ ... }:

{
  services.hyprpaper = {
    enable = true;

    settings = {
      splash = false;

      # Set these paths to your actual wallpapers
      preload = [
        "$HOME/.config/hypr/wallpaper/wallpaper1.jpg"
      ];

      wallpaper = [
        ",$HOME/.config/hypr/wallpaper/wallpaper1.jpg"
      ];
    };
  };
}
