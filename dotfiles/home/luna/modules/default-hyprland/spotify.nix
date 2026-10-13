{ lib, pkgs, ... }:
let
  inherit (lib.generators) mkLuaInline toLua;

  # Spotify lebt immer auf diesem Workspace und wird dort still gestartet
  workspace = 3;

  playerctl = "${pkgs.playerctl}/bin/playerctl -p spotify";
  notifySend = "${pkgs.libnotify}/bin/notify-send -a Spotify";

  # Nach dem Start soll der erste Play den letzten Song von vorne spielen, statt
  # an der gespeicherten Stelle weiterzumachen. Die Marke wird beim Start gesetzt
  # und beim ersten Abspielen (auch direkt in Spotify) wieder entfernt.
  freshMark = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/spotify-fresh"'';
  # zuletzt gespielter Song (von spotify-track-watch geschrieben)
  lastTrack = ''"''${XDG_STATE_HOME:-$HOME/.local/state}/spotify-last-track"'';

  ctl = pkgs.writeShellScript "spotify-ctl" ''
    p="${playerctl}"
    mark=${freshMark}
    last=${lastTrack}
    notify() { ${notifySend} -t 1500 -h string:x-canonical-private-synchronous:spotify "$1"; }
    running() { ${pkgs.procps}/bin/pgrep -f '/share/spotify/\.spotify-wrapped' >/dev/null; }
    launch() {
      running && return
      touch "$mark"
      hyprctl eval "hl.exec_cmd('spotify', { workspace = '${toString workspace} silent' })" >/dev/null
    }
    case "$1" in
      launch) launch ;;
      play)
        if ! $p status >/dev/null 2>&1; then
          launch
          # warten, bis Spotify per MPRIS erreichbar ist
          for _ in $(seq 60); do $p status >/dev/null 2>&1 && break; sleep 0.5; done
        fi
        if [ -e "$mark" ] && [ "$($p status)" != Playing ]; then
          # Spotify zeigt nach dem Start kurz einen alten, lokal gecachten Song und
          # synchronisiert erst danach den zuletzt gehörten. Warten, bis der gemerkte
          # Song geladen ist oder sich 2 s nichts mehr ändert (max. 8 s).
          want=$(cat "$last" 2>/dev/null) prev="" stable=0
          for _ in $(seq 32); do
            id=$($p metadata mpris:trackid 2>/dev/null)
            [ -n "$want" ] && [ "$id" = "$want" ] && break
            if [ "$id" = "$prev" ]; then stable=$((stable + 1)); else stable=0; prev=$id; fi
            [ "$stable" -ge 8 ] && break
            sleep 0.25
          done
          # Spotify ignoriert Play direkt nach dem Start manchmal -> wiederholen
          for _ in $(seq 30); do
            $p play; sleep 0.5
            [ "$($p status)" = Playing ] && break
          done
          $p position 0
          rm -f "$mark"
        else
          $p play-pause
        fi ;;
      shuffle)
        # Spotify meldet den Zustand per MPRIS erst ~0,5 s später, daher selbst berechnen
        if [ "$($p shuffle)" = On ]; then $p shuffle Off && notify "Shuffle aus"
        else $p shuffle On && notify "Shuffle an"; fi ;;
      repeat)
        case "$($p loop)" in
          None) $p loop Playlist && notify "Repeat: Playlist" ;;
          Playlist) $p loop Track && notify "Repeat: Song" ;;
          *) $p loop None && notify "Repeat aus" ;;
        esac ;;
    esac
  '';

  # Merkt sich bei jedem Songwechsel den Song (nur wenn auch wirklich gespielt wird)
  trackWatch = pkgs.writeShellScript "spotify-track-watch" ''
    mark=${freshMark}
    state=${lastTrack}
    mkdir -p "$(dirname "$state")"
    last=""
    ${playerctl} metadata --follow --format "{{status}} {{mpris:trackid}}" |
      while read -r status id; do
        # leere Zeile = Spotify wurde beendet
        [ -n "$id" ] || { last=""; continue; }
        [ "$status" = Playing ] || continue
        rm -f "$mark"
        [ "$id" != "$last" ] || continue
        last=$id
        echo "$id" > "$state"
      done
  '';

  bind = keys: cmd: {
    _args = [
      (mkLuaInline ''mainMod .. " + ${keys}"'')
      (mkLuaInline "hl.dsp.exec_cmd(${toLua { } cmd})")
      { locked = true; }
    ];
  };
in
{
  wayland.windowManager.hyprland.settings = {
    # SUPER + Leertaste = Play/Pause (startet Spotify bei Bedarf still auf Workspace ${toString workspace}),
    # SUPER + . / , = nächster / vorheriger Song,
    # SUPER + Z = Shuffle (Zufall), SUPER + W = Repeat (Wiederholen: aus -> Playlist -> Song)
    bind = [
      (bind "SPACE" "${ctl} play")
      (bind "period" "${playerctl} next")
      (bind "comma" "${playerctl} previous")
      (bind "Z" "${ctl} shuffle")
      (bind "W" "${ctl} repeat")
    ];

    on = [
      {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd(${toLua { } "${ctl} launch"})
            end'')
        ];
      }
    ];
  };

  systemd.user.services.spotify-track-watch = {
    Unit = {
      Description = "Merkt sich den zuletzt gespielten Spotify-Song";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${trackWatch}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
