{ ... }:

{
  programs.yazi = {
    enable = true;

    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
        linemode = "size";
      };

      opener = {
        edit = [
          {
            run = "nvim \"$@\"";
            block = true;
          }
        ];
      };

      open = {
        # Defaults NICHT überschreiben – nur vorne ergänzen:
        prepend_rules = [
          # Wichtig für neue/leere Dateien: Extension matcht immer
          { url = "*.nix"; use = "edit"; }

          # Allgemein Textdateien
          { mime = "text/*"; use = "edit"; }
        ];
      };
    };
  };
}

