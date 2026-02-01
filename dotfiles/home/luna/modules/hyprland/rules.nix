{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "workspace special:spotify, class:spotify"
      "float, class:^(Spotify|com\\.spotify\\.Client)$"
      "pin, class:^(Spotify|com\\.spotify\\.Client)$"
      "size 1200 700, class:^(Spotify|com\\.spotify\\.Client)$"
      "center, class:^(Spotify|com\\.spotify\\.Client)$"
    ];
  };
}

