{ config, pkgs, ... }:
{
  # Beispiel: SDDM-Theme (du nutzt schon Catppuccin im Systempaket)
  services.displayManager.sddm = {
    enable = true;
    theme = "catppuccin-mocha-mauve";
  };


  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      # CJK Fonts (das ist der entscheidende Fix)
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK KR"
        ];

        sansSerif = [
          "Noto Sans CJK KR"
        ];

        serif = [
          "Noto Serif CJK KR"
        ];
      };
    };
  };
}

