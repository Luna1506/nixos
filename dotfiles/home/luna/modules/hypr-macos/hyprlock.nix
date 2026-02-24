{ ... }:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 2;
      };

      background = [{
        path = "$HOME/.config/hypr/wallpaper/wallpaper1.jpg";
        blur_passes = 3;
        blur_size = 10;
        noise = 0.01;
        contrast = 1.05;
        brightness = 0.9;
      }];

      label = [{
        text = "$TIME";
        font_size = 80;
        position = "0, 200";
        halign = "center";
        valign = "center";
        color = "rgba(255,255,255,0.92)";
        shadow_passes = 2;
        shadow_size = 4;
      }];

      input-field = [{
        size = "380, 56";
        position = "0, -40";
        halign = "center";
        valign = "center";

        outline_thickness = 2;
        rounding = 18;

        font_size = 18;

        outer_color = "rgba(255,255,255,0.25)";
        inner_color = "rgba(20,20,24,0.35)";
        font_color = "rgba(255,255,255,0.95)";
        fade_on_empty = true;
      }];
    };
  };
}
