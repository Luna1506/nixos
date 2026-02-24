{ ... }:

let
  terminal = "ghostty";
  fileManager = "nautilus";
  menu = "wofi --show drun";
  mainMod = "SUPER";
in
{
  wayland.windowManager.hyprland.settings = {
    "$terminal" = terminal;
    "$fileManager" = fileManager;
    "$menu" = menu;
    "$mainMod" = mainMod;
  };
}

