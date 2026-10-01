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
        panel_peek = vela.panelPeek;
        keycodes = [ ];
      }
    })
  '';

  home.packages = with pkgs; [
    brightnessctl # XF86-Helligkeitstasten (binds.nix)
    hyprsunset # Nachtlicht im Control Center
  ];
}
