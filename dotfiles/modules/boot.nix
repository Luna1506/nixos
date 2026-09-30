{ pkgs, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "nvidia_drm.modeset=1" ];
    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
  };

  # Windows (und HP-Firmware) schieben "Windows Boot Manager" immer wieder an
  # Platz 1 der UEFI-BootOrder. Bei jedem Linux-Boot wieder zurechtrücken.
  systemd.services.fix-efi-boot-order = {
    description = "Put Linux Boot Manager first in UEFI BootOrder";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/sys/firmware/efi";
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ efibootmgr gnused gnugrep coreutils ];
    script = ''
      linux=$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)\*\? Linux Boot Manager.*/\1/p' | head -n1)
      [ -n "$linux" ] || exit 0
      order=$(efibootmgr | sed -n 's/^BootOrder: //p')
      case "$order" in "$linux"*) exit 0 ;; esac
      # HP-Firmware lässt tote IDs in der BootOrder stehen, die efibootmgr -o ablehnt
      existing=$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\).*/\1/p')
      rest=$(echo "$order" | tr ',' '\n' | grep -vx "$linux" | grep -Fx "$existing" | paste -sd, -)
      efibootmgr -o "$linux''${rest:+,$rest}" >/dev/null
    '';
  };
}

