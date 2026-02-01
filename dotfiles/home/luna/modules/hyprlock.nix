{ ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };

      background = {
        monitor = "";
        path = ""; # leer = letzter Wallpaper
        blur_passes = 3;
        blur_size = 8;
      };

      input-field = {
        monitor = "";
        size = "300, 60";
        position = "0, -80";
        halign = "center";
        valign = "center";

        rounding = 8;

        border_size = 1;
        border_color = "rgba(255,255,255,1.0)";

        outline_thickness = 0;

        font_color = "rgba(255,255,255,1.0)";
        inner_color = "rgba(0,0,0,0.4)";
        outer_color = "rgba(0,0,0,0.0)";

        placeholder_text = "<i>Password…</i>";
        dots_center = true;
        dots_spacing = 0.3;
        dots_rounding = -1;
      };

      label = {
        monitor = "";
        text = "Enter Password";
        font_size = 18;
        color = "rgba(255,255,255,0.8)";
        position = "0, -150";
        halign = "center";
        valign = "center";
      };
    };
  };
}

