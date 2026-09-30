{ lib, ... }:
{
  wayland.windowManager.hyprland.settings = {
    env = [
      { _args = [ "XCURSOR_THEME" "Bibata-Modern-Classic" ]; }
      { _args = [ "XCURSOR_SIZE" "25" ]; }
    ];
  };

  # Also export the cursor to systemd/D-Bus activated programs, e.g. apps
  # started from the Quickshell launcher (in addition to the default list).
  wayland.windowManager.hyprland.systemd.variables = lib.mkOptionDefault [
    "XCURSOR_THEME"
    "XCURSOR_SIZE"
  ];
}
