{ ... }:

{
  # We store rules as strings and later join them in hyprland.nix
  config.hyprMacos.windowRules = [
    # Floating utility apps
    "float, class:^(pavucontrol)$"
    "size 900 650, class:^(pavucontrol)$"
    "center, class:^(pavucontrol)$"

    "float, class:^(org\.gtk\.FileChooser)$"
    "center, class:^(org\.gtk\.FileChooser)$"

    # Picture-in-picture (example: Firefox PiP)
    "float, title:^(Picture-in-Picture)$"
    "pin, title:^(Picture-in-Picture)$"
    "size 640 360, title:^(Picture-in-Picture)$"
    "move 100%-700 80, title:^(Picture-in-Picture)$"

    # Rofi/launcher: no blur override (optional, but often feels more "mac")
    "noblur, class:^(Rofi)$"
    "float, class:^(Rofi)$"
    "center, class:^(Rofi)$"
  ];
}
