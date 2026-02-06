{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(Spotify|com\\.spotify\\.Client)$, workspace special:spotify"
      "match:class ^(Spotify|com\\.spotify\\.Client)$, float on"
      "match:class ^(Spotify|com\\.spotify\\.Client)$, center on"
      "match:class ^(Spotify|com\\.spotify\\.Client)$, size 1200 700"
      "match:class ^(Spotify|com\\.spotify\\.Client)$, opacity 0.92 override"
    ];
  };
}

