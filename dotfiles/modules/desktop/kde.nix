# /home/luna/nixos/dotfiles/modules/kde.nix
{ config, pkgs, lib, ... }:

{
  # KDE Plasma (Plasma 6) als Desktop aktivieren
  services.desktopManager.plasma6.enable = true;

  # Nützliche KDE Tools (optional – kannst du kürzen)
  environment.systemPackages = with pkgs; [
    kdePackages.kdeconnect-kde
    kdePackages.kcalc
    kdePackages.dolphin
    kdePackages.okular
    kdePackages.spectacle
  ];
}
