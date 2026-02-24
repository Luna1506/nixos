{ ... }:

{
  programs.rofi = {
    enable = true;
    package = null; # rofi-wayland via home.packages

    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
    };

    theme = builtins.toFile "macos-glass.rasi" ''
      * {
        bg: rgba(20,20,24,0.40);
        fg: rgba(255,255,255,0.95);
        accent: rgba(255,255,255,0.12);
        radius: 18px;
      }

      window {
        background-color: @bg;
        border-radius: @radius;
        padding: 18px;
      }

      entry {
        background-color: rgba(255,255,255,0.10);
        border-radius: 14px;
        padding: 10px;
        text-color: @fg;
      }

      element {
        padding: 10px;
        border-radius: 14px;
      }

      element selected {
        background-color: rgba(255,255,255,0.14);
      }
    '';
  };
}
