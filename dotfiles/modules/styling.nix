{ config, pkgs, ... }:
{
  # Beispiel: SDDM-Theme (du nutzt schon Catppuccin im Systempaket)
  services.displayManager.sddm = {
    enable = true;
    theme = "catppuccin-mocha-mauve";
  };

  fonts = {
    fontconfig.enable = true;

    # Wichtig: Fonts hier rein, nicht nur systemPackages
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
  };
}

