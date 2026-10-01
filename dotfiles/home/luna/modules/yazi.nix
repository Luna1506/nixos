{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
        linemode = "size";
      };

      opener = {
        edit = [
          {
            # Yazi >= 26 expands %s to the selected files ("$@" stays empty).
            run = "nvim %s";
            block = true;
          }
        ];
        pdf = [
          {
            # Zen statt dem xdg-open-Fallback Firefox.
            run = "zen %s";
            orphan = true;
            desc = "Zen Browser";
          }
        ];
      };

      open = {
        # Defaults NICHT überschreiben – nur vorne ergänzen:
        prepend_rules = [
          # Wichtig für neue/leere Dateien: Extension matcht immer
          { url = "*.nix"; use = "edit"; }

          { mime = "application/pdf"; use = "pdf"; }

          # Allgemein Textdateien
          { mime = "text/*"; use = "edit"; }
        ];
      };
    };
  };
}

