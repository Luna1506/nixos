{ zoom, ... }:
{
  wayland.windowManager.hyprland.settings = {
    monitor = [ ",preferred,auto,${zoom}" ];
  };
}

