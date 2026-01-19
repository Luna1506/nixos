{ pkgs, ... }:

{
  programs.wofi.enable = true;

  home.file.".config/wofi/style.css".text = pkgs.runCommand "compile-wofi-style" {
    buildInputs = [ pkgs.sass ];
  } ''
    sass ./wofi/style.scss style.css
    mkdir -p $out
    cp style.css $out/
  '';
}

