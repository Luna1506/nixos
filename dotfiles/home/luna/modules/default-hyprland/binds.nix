{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline toLua;

  # key: Taste(n) hinter mainMod, z.B. "Q" oder "SHIFT + E"
  mod = key: mkLuaInline ''mainMod .. " + ${key}"'';
  bind = keys: dispatcher: { _args = [ keys (mkLuaInline dispatcher) ]; };
  bindWith = opts: keys: dispatcher: { _args = [ keys (mkLuaInline dispatcher) opts ]; };
  exec = cmd: "hl.dsp.exec_cmd(${toLua { } cmd})";

  media = bindWith { locked = true; repeating = true; };
  mediaLocked = bindWith { locked = true; };
  mouse = bindWith { mouse = true; };

  # mainMod + [0-9] -> Workspace, mainMod + SHIFT + [0-9] -> Fenster verschieben
  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10);
      ws = toString i;
    in
    [
      (bind (mod key) "hl.dsp.focus({ workspace = ${ws} })")
      (bind (mod "SHIFT + ${key}") "hl.dsp.window.move({ workspace = ${ws}, follow = true })")
    ]
  ) (lib.range 1 10);
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      (bind (mod "Q") "hl.dsp.exec_cmd(terminal)")
      (bind (mod "C") "hl.dsp.window.close()")
      (bind (mod "M") "hl.dsp.exit()")
      (bind (mod "E") "hl.dsp.exec_cmd(fileManager)")
      (bind (mod "T") ''hl.dsp.window.float({ action = "toggle" })'')
      (bind (mod "R") "hl.dsp.exec_cmd(menu)")
      (bind (mod "P") ''hl.dsp.window.pin({ action = "toggle" })'')
      (bind (mod "J") ''hl.dsp.layout("togglesplit")'')
      (bind (mod "F") ''hl.dsp.window.fullscreen({ action = "toggle" })'')
      (bind (mod "L") (exec "hyprlock"))
      (bind (mod "D") (exec ''grim -g "$(slurp)" - | wl-copy''))
      (bind (mod "SHIFT + E") "hl.dsp.exit()")
      (bind (mod "V") (exec "cliphist list | wofi -dmenu | cliphist decode | wl-copy"))
      (bind (mod "SHIFT + TAB") (exec "qs ipc -c overview call overview toggle"))
    ]
    ++ workspaceBinds
    ++ [
      (bind (mod "S") ''hl.dsp.workspace.toggle_special("magic")'')
      (bind (mod "SHIFT + S") ''hl.dsp.window.move({ workspace = "special:magic" })'')
      (bind (mod "TAB") ''hl.dsp.focus({ workspace = "e+1" })'')
      (bind (mod "right") ''hl.dsp.focus({ workspace = "e+1" })'')
      (bind (mod "left") ''hl.dsp.focus({ workspace = "e-1" })'')
      (bind "ALT + Tab" ''hl.dsp.focus({ workspace = "previous" })'')

      (mouse (mod "mouse:272") "hl.dsp.window.drag()")
      (mouse (mod "mouse:273") "hl.dsp.window.resize()")

      (media "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
      (media "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      (media "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      (media "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      (media "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+"))
      (media "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-"))

      (mediaLocked "XF86AudioNext" (exec "playerctl next"))
      (mediaLocked "XF86AudioPause" (exec "playerctl play-pause"))
      (mediaLocked "XF86AudioPlay" (exec "playerctl play-pause"))
      (mediaLocked "XF86AudioPrev" (exec "playerctl previous"))
    ];
  };
}
