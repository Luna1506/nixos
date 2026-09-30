{ ... }:

# Werden als Lua-Locals (`local terminal = "ghostty"` ...) an den Anfang von
# hyprland.lua geschrieben und können in Binds/Autostart referenziert werden.
{
  wayland.windowManager.hyprland.settings = {
    terminal._var = "ghostty";
    fileManager._var = "nautilus";
    mainMod._var = "SUPER";
  };
}
