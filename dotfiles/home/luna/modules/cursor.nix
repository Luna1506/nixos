{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 15;
    gtk.enable = true;
    x11.enable = true;
  };
}

