{ config, pkgs, lib, ... }:
{
  # X11 aktivieren, wenn SDDM im X11-Modus läuft
  services.xserver.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true; # Baseline: X11-Greeter (NVIDIA-sicherer)
    };

    # Hyprland als Default-Session
    defaultSession = "hyprland";
  };
}

