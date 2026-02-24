{ ... }:

{
  home.sessionVariables = {
    # Wayland hints
    NIXOS_OZONE_WL = "1";

    # If you use NVIDIA, you may want these too (optional):
    # WLR_NO_HARDWARE_CURSORS = "1";

    # Toolkit hints
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
