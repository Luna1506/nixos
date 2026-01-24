{ inputs, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Thematische Module
    ../../modules/boot.nix
    ../../modules/nix.nix
    ../../modules/networking.nix
    ../../modules/locale.nix
    ../../modules/users.nix
    ../../modules/aliases.nix
    ../../modules/packages.nix
    ../../modules/styling.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/display-manager.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/docker.nix
  ];

  networking.hostName = "nixos";

  # Empfohlen: Polkit sauber aktivieren (anstatt eigener systemd-Unit)
  security.polkit.enable = true;

  # Wichtig: Dieses Feld sollte der NixOS-Version deiner ERSTinstallation entsprechen.
  # In deiner Konfiguration stand "25.11", aktuell existiert 24.11 stabil.
  system.stateVersion = "24.11";
}

