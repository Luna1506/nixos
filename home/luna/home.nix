{ pkgs, ... }:

{
  home.username = "luna";
  home.homeDirectory = "/home/luna";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Alternativ: Module direkt einbinden
  imports = [
    ./modules/hyprland.nix
    ./modules/gpg.nix
    ./modules/git.nix
    ./modules/yazi.nix
    ./modules/cursor.nix
    ./modules/hyprpaper.nix
    ./modules/theme.nix
    #    ./modules/wofi.nix
    ./modules/ghostty.nix
    ./modules/neovim.nix
  ];
}

