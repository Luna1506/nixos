{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    open = true;

    nvidiaSettings = true;

    # nimm beta oder latest (stable ist sehr wahrscheinlich zu alt)
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    # alternativ:
    # package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Desktop/Display an NVIDIA: kein PRIME-offload nötig
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  boot.loader.systemd-boot.configurationLimit = 5;
}
