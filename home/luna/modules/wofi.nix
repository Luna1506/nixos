{ pkgs, ... }:

{
  programs.wofi = {
    enable = true;

    settings = {
      show = "drun";
      allow_images = true;
      gtk_dark = true;
      width = 600;
      height = 400;
    };
  };

  # Wofi CSS direkt kopieren
  home.file.".config/wofi/style.css".text = pkgs.runCommand "compile-wofi-style" {
    buildInputs = [ pkgs.sass ];
  } ''
    sass ./wofi/style.scss style.css
    mkdir -p $out
    cp style.css $out/
  '';
}

