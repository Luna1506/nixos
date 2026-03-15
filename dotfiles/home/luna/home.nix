{ inputs, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];

  # Alternativ: Module direkt einbinden
  imports = [
    ./modules/default-hyprland
    ./modules/gpg.nix
    ./modules/git.nix
    ./modules/yazi.nix
    ./modules/cursor.nix
    ./modules/neovim.nix
    ./modules/nerdfetch-bash.nix
    inputs.quickpanel.homeManagerModules.default
  ];

  programs.quickpanel = {
    enable = true;
    keybind = "SUPER SHIFT, P";
    autostart = true;
    extraPackages = with pkgs; [ networkmanager bluez upower playerctl ];
  };

}

