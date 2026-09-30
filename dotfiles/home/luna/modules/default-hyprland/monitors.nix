{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      { output = "eDP-1"; mode = "1920x1080@144"; position = "0x0"; scale = 1; }
      { output = "HDMI-A-1"; mode = "2560x1440@75"; position = "1920x0"; scale = 1; }
      { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
    ];
  };
}
