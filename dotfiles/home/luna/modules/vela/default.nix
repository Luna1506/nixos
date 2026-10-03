{ config, inputs, lib, pkgs, username, ... }:

# vela (github:raindancer118/vela): launcher (SUPER+R, siehe ./state), Control
# Center (SUPER+B), Benachrichtigungen, Workspace-OSD und alle Hyprland-Einstellungen.
# Was vela ändert, landet in ./state (config.toml, hyprland.toml/.lua);
# "Apply & rebuild" in den vela-Settings committet und rebuildet.
let
  vela = config.programs.vela;
in
{
  imports = [ inputs.vela.homeManagerModules.default ];

  programs.vela = {
    enable = true;
    panelPeek = "SUPER + B";
    # Volles Profil ohne Updates (pacman/Flatpak; NixOS updatet über die Flake,
    # updates ist im Modul ohnehin aus). share_picker schreibt ~/.config/hypr/xdph.conf.
    components = {
      share_picker = true;
      updates = false;
    };
    nixos = {
      # String, kein Nix-Pfad: vela schreibt hier hinein.
      stateDir = "/home/${username}/nixos/dotfiles/home/${username}/modules/vela/state";
      rebuildCommand = "rebuild vela";
    };
  };

  # Ersetzt den setup()-Aufruf des vela-Moduls, das keine Option für das
  # Super-Antippen hat: ohne Keycodes öffnet Super allein den Launcher nicht mehr.
  wayland.windowManager.hyprland.extraConfig = lib.mkForce ''
    -- vela: control center, idle and vela's Hyprland settings (kein Super-Antippen)
    dofile("${vela.package}/share/vela/vela.lua").setup(${
      lib.generators.toLua { } {
        binary = lib.getExe vela.package;
        settings_file = "${vela.nixos.stateDir}/hyprland.lua";
        # Settings → System → Features speichert dort (seit 0.44.0).
        components_file = "${vela.nixos.stateDir}/components.toml";
        panel_peek = vela.panelPeek;
        keycodes = [ ];
      }
    })
    -- Die Catch-all-Regel aus look.nix (ignore_alpha = 0.3) würde den fast
    -- durchsichtigen Blur-Hintergrund hinter Panel und Launcher nie blurren.
    hl.layer_rule({
      name = "vela-backdrop-alpha",
      match = { namespace = "^vela-(shell-)?backdrop$" },
      ignore_alpha = 0,
    })
  '';

  # vela erkennt Updates nur daran, dass sich die eigene Binary ändert (Arch).
  # Unter NixOS liegt jede Version unter einem neuen Store-Pfad: Control Center
  # und Idle liefen bis zum nächsten Login alt weiter, und SUPER+B (neue Binary)
  # fand die Quickshell-Instanz der alten Version nicht. Hier werden veraltete
  # Instanzen beendet und über Hyprland mit der neuen Version neu gestartet.
  home.activation.velaRestartStale = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    vela_restart_stale() {
      local pattern=$1 cmd=$2 pids
      pids=$(${pkgs.procps}/bin/pgrep -af "$pattern" | grep -vF "${vela.package}/" | cut -d' ' -f1 || true)
      [ -n "$pids" ] || return 0
      verboseEcho "vela: veraltete Instanz ($cmd) wird neu gestartet"
      run kill $pids || true
      [ -z "$cmd" ] || run /run/current-system/sw/bin/hyprctl -i 0 eval \
        "hl.exec_cmd('${lib.getExe vela.package} $cmd')" >/dev/null || true
    }
    vela_restart_stale 'quickshell -p /nix/store/[^ ]*-vela-[^ /]*/.*share/vela/shell$' shell
    vela_restart_stale '^/nix/store/[^ ]*-vela-[^ /]*/bin/vela idle$' idle
    # Pulse nur beenden; Ctrl+Shift+Esc startet ihn in der neuen Version.
    vela_restart_stale 'quickshell -p /nix/store/[^ ]*-vela-[^ /]*/.*share/vela/shell/pulse\.qml$' ""

    # Der Launcher beobachtet die applications-Ordner per inotify; ein Rebuild
    # biegt aber nur die Profil-Symlinks um, neue Programme sähe er erst nach
    # einem Neustart. Über Hyprland, damit vela seinen IPC-Socket findet.
    run /run/current-system/sw/bin/hyprctl -i 0 eval \
      "hl.exec_cmd('${lib.getExe vela.package} reload')" >/dev/null 2>&1 || true
  '';

  home.packages = with pkgs; [
    brightnessctl # XF86-Helligkeitstasten (binds.nix)
    hyprsunset # Nachtlicht im Control Center
  ];
}
