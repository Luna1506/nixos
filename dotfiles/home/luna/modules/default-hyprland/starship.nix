{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    package = pkgs.starship;
    enableBashIntegration = true;

    settings = {
      add_newline = false;

      format = "$username$hostname$directory$git_branch$character";

      username = {
        show_always = true;
        style_user = "bold white";
        format = "< [$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bold white";
        format = "@[$hostname]($style) ";
      };

      directory = {
        style = "bold white";
        format = "[$path]($style) ";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      git_branch = {
        style = "bold white";
        format = ": [$branch]($style) ";
      };

      character = {
        success_symbol = "[>](bold white) ";
        error_symbol = "[>](bold white) ";
      };
    };
  };
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(starship init bash)"
    '';
  };

}

