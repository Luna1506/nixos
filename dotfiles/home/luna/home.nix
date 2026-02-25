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
    ./modules/quickshell
  ];

  programs.quickshellBarDock = {
    enable = true;
    autostart = true;
    configName = "default";
  };

  programs.quickshellOverview = {
    enable = true;

    # nach dem fakeSha256-run ersetzen:
    rev = "main"; # besser: commit hash pinnen
    sha256 = "sha256-Y9VJTv62yR3rjIdZz1SJEL9ithL6CnFiTBU1zs8b6+U=";
  };
}

