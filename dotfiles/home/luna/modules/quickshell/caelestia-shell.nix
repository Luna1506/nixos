{ config, lib, pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Caelestias eigenes Home-Manager Modul aus dem Flake-Input verwenden
  imports = [
    # Manche Flakes exportieren "default", manche direkt das Modulset.
    # Das hier ist defensiv und sollte in den meisten Fällen passen.
    (
      inputs.caelestia-shell.homeManagerModules.default
        or inputs.caelestia-shell.homeManagerModules.caelestia
        or inputs.caelestia-shell.homeManagerModules
    )
  ];

  # Optional: Tools, die du eh dauernd brauchst
  home.packages = with pkgs; [
    ripgrep
  ];

  programs.caelestia = {
    enable = true;

    # Wenn du es lieber im Hyprland-Autostart startest: enable=false
    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [
        # falls du hier später Sachen brauchst (z.B. extra QML paths),
        # kannst du das Array füllen. Erstmal leer lassen.
      ];
    };

    # Shell settings (Beispiel aus dem README)
    settings = {
      bar.status.showBattery = false;
      paths.wallpaperDir = "~/Images";
    };

    # CLI (wichtig laut README für „full functionality“)
    cli = {
      enable = true;
      settings = {
        theme.enableGtk = false;
      };
    };
  };
}
