{ ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = {
        monitor = "";
        size = "320, 64";
        position = "0, -40";
        halign = "center";
        valign = "center";

        rounding = 12;

        inner_color = "rgba(00000066)";
        outer_color = "rgba(ffffffff)";
        outline_thickness = 1;

        font_color = "rgba(ffffffff)";
        placeholder_text = "Enter password...";
        dots_center = true;
        dots_spacing = 0.30;

        # 👇 DAS ist der Fix: Feld bleibt sichtbar, auch wenn leer
        fade_on_empty = false;
      };

    };
  };
}

