{ inputs, pkgs, username, ... }:

# vela (github:raindancer118/vela): launcher (Super antippen), Control Center
# (SUPER+B), Benachrichtigungen, Workspace-OSD und alle Hyprland-Einstellungen.
# Was vela ändert, landet in ./state (config.toml, hyprland.toml/.lua);
# "Apply & rebuild" in den vela-Settings committet und rebuildet.
{
  imports = [ inputs.vela.homeManagerModules.default ];

  programs.vela = {
    enable = true;
    panelPeek = "SUPER + B";
    nixos = {
      # String, kein Nix-Pfad: vela schreibt hier hinein.
      stateDir = "/home/${username}/nixos/dotfiles/home/${username}/modules/vela/state";
      rebuildCommand = "rebuild vela";
    };
  };

  home.packages = with pkgs; [
    brightnessctl # XF86-Helligkeitstasten (binds.nix)
    hyprsunset # Nachtlicht im Control Center
  ];
}
