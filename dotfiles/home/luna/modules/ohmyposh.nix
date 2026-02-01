{ pkgs, ... }:
{
  programs.oh-my-posh = {
    enable = true;
    package = pkgs.oh-my-posh;
    # WICHTIG: keine automatische Bash-Integration, sonst lädt er evtl. ein anderes Theme
    enableBashIntegration = false;
  };

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
              "style": "powerline",
              "foreground": "#000000",
              "background": "#ffffff",
              "powerline_symbol": ""
            },
            {
              "type": "path",
              "style": "powerline",
              "foreground": "#000000",
              "background": "#ffffff",
              "powerline_symbol": "",
              "properties": { "style": "folder" }
            },
            {
              "type": "git",
              "style": "powerline",
              "foreground": "#000000",
              "background": "#ffffff",
              "powerline_symbol": "",
              "properties": { "branch_icon": " " }
            }
          ]
        }
      ]
    }
  '';

  programs.bash = {
    enable = true;

    # ganz am Ende initialisieren, damit nichts danach dein Prompt überschreibt
    initExtra = ''
      eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/theme.json)"
    '';
  };
}

