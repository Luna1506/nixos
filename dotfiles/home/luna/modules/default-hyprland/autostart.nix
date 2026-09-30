{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline toLua;

  # Wird beim Start von Hyprland ausgeführt (ersetzt exec-once).
  # Strings sind Shell-Befehle, mkLuaInline-Werte rohe Lua-Ausdrücke.
  startup = [
    "hyprpaper"
    (mkLuaInline "terminal")
    "wl-paste --type text --watch cliphist store"
  ];
in
{
  wayland.windowManager.hyprland.settings = {
    on = [
      {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
            ${lib.concatMapStrings (cmd: "  hl.exec_cmd(${toLua { } cmd})\n") startup}end'')
        ];
      }
    ];
  };
}
