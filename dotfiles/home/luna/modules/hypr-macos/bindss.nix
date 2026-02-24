{ ... }:

{
  config.hyprMacos.binds = [
    # App launcher
    "SUPER, R, exec, rofi -show drun"

    # Terminal (change to your terminal)
    "SUPER, RETURN, exec, ghostty"

    # Browser (change if needed)
    "SUPER, B, exec, zen-browser"

    # Screenshot selection -> clipboard
    "SUPER, D, exec, grim -g \"$(slurp)\" - | wl-copy"

    # Audio
    ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
    ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
    ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"

    # Brightness
    ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
    ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

    # Media
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPrev, exec, playerctl previous"

    # Dock toggle (nwg-dock-hyprland)
    "SUPER, G, exec, nwg-dock-hyprland -d"

    # Notifications center toggle
    "SUPER, N, exec, swaync-client -t -sw"

    # Lock
    "SUPER, L, exec, hyprlock"

    # Quit / reload
    "SUPER SHIFT, Q, exit,"
    "SUPER SHIFT, R, exec, hyprctl reload"
  ];
}
