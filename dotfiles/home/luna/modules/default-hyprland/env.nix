{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    env = [
      { _args = [ "XCURSOR_THEME" "Bibata-Modern-Classic" ]; }
      { _args = [ "XCURSOR_SIZE" "25" ]; }
    ];
  };
}
