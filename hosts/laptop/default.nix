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

  # Host-spezifische Filesystems (dein Steam-Mount)
  fileSystems."/mnt/steam" = {
    device = "/dev/disk/by-uuid/6bc50fd0-d0d8-458e-b5c4-589b1319af0f";
    fsType = "ext4";
    options = [ "nofail" "rw" ];
  };

  # Empfohlen: Polkit sauber aktivieren (anstatt eigener systemd-Unit)
  security.polkit.enable = true;

  # Wichtig: Dieses Feld sollte der NixOS-Version deiner ERSTinstallation entsprechen.
  # In deiner Konfiguration stand "25.11", aktuell existiert 24.11 stabil.
  system.stateVersion = "24.11";
}

