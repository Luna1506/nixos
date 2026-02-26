{ pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Alternativ: Module direkt einbinden
  imports = [
    ./modules/default-hyprland
    ./modules/gpg.nix
    ./modules/git.nix
    ./modules/yazi.nix
    ./modules/cursor.nix
    ./modules/neovim.nix
    ./modules/nerdfetch-bash.nix
    #  ./modules/quickshell/caelestia-shell.nix
  ];

  #programs.caelestiaShell = {
  #  enable = true;
  #};
}

