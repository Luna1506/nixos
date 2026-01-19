{ pkgs, ... }:

{
  home.username = "luna";
  home.homeDirectory = "/home/luna";
  home.stateVersion = "23.11";  

  programs.home-manager.enable = true;

#  programs.gpg.enable = true;
#  services.gpg-agent = {
#    enable = true;
#    pinentryPackage = pkgs.pinentry-curses;
#  };

  # Alternativ: Module direkt einbinden
  imports = [
    ./modules/hyprland.nix
    ./modules/gpg.nix
    ./modules/git.nix
    ./modules/yazi.nix
    ./modules/cursor.nix
    ./modules/hyprpaper.nix
  ];
}

