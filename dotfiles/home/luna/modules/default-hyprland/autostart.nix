{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline toLua;

  # Wird beim Start von Hyprland ausgeführt (ersetzt exec-once).
  # Strings sind Shell-Befehle, mkLuaInline-Werte rohe Lua-Ausdrücke,
  # { cmd; workspace; } startet still auf dem Workspace (ohne dorthin zu wechseln).
  # Spotify (Workspace 3) startet aus ./spotify.nix.
  startup = [
    "hyprpaper"
    (mkLuaInline "terminal")
    "wl-paste --type text --watch cliphist store"
    { cmd = "zen"; workspace = 2; }
  ];

  execCmd =
    cmd:
    if cmd ? workspace then
      "hl.exec_cmd(${toLua { } cmd.cmd}, { workspace = \"${toString cmd.workspace} silent\" })"
    else
      "hl.exec_cmd(${toLua { } cmd})";
in
{
  wayland.windowManager.hyprland.settings = {
    on = [
      {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
            ${lib.concatMapStrings (cmd: "  ${execCmd cmd}\n") startup}end'')
        ];
      }
    ];
  };
}
