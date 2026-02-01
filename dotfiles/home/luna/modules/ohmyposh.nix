{ pkgs, ... }:
{
  programs.oh-my-posh = {
    enable = true;
    package = pkgs.oh-my-posh;

    # WICHTIG: keine automatische Bash-Integration,
    # sonst lädt evtl. ein Default-Theme mit Farben
    enableBashIntegration = false;
  };

  # oh-my-posh Theme – komplett monochrom, KEINE backgrounds
  home.file.".config/ohmyposh/theme.json".text = ''
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "version": 2,
      "final_space": true,

      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "session",
              "style": "plain",
              "foreground": "#ffffff"
            },
            {
              "type": "text",
              "text": "➜",
              "style": "plain",
              "foreground": "#888888"
            },
            {
              "type": "path",
              "style": "plain",
              "foreground": "#ffffff",
              "properties": {
                "style": "folder"
              }
            },
            {
              "type": "git",
              "style": "plain",
              "foreground": "#aaaaaa",
              "properties": {
                "branch_icon": " "
              }
            }
          ]
        }
      ]
    }
  '';

  # Bash lädt GENAU dieses Theme
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/theme.json)"
    '';
  };
}

