{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    "exec-once" = [
      "$terminal"
      "hyprpaper"
      "~/.config/hypr/scripts/waybar-toggle.sh"
    ];
  };
}

