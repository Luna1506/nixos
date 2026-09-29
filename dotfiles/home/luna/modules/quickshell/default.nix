{ pkgs, ... }:

# Quickshell desktop shell: control center (SUPER+N), notification popups and
# a workspace OSD. There is no permanent bar; nothing is visible until used.
#
# QML lives in ./config and is linked to ~/.config/quickshell/luna.
# Live-edit while developing:  qs -p ~/nixos/dotfiles/home/luna/modules/quickshell/config
let
  configName = "luna";
  target = "hyprland-session.target";
in
{
  programs.quickshell = {
    enable = true;
    configs.${configName} = ./config;
    activeConfig = configName;
    systemd = {
      enable = true;
      inherit target;
    };
  };

  # Restart/stop together with the Hyprland session instead of lingering.
  systemd.user.services.quickshell.Unit.PartOf = [ target ];

  home.packages = with pkgs; [
    brightnessctl # brightness slider (also used by the XF86 brightness keys)
    hyprsunset # night light
    material-symbols # icon font (Material Symbols Rounded)
    rubik # UI font
  ];

  # Make the user-profile fonts above visible to fontconfig.
  fonts.fontconfig.enable = true;

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, N, global, quickshell:panelToggle"
    ];

    # The shell animates its own surfaces; Hyprland's layer animations would
    # run on top of that.
    layerrule = [
      "no_anim on, match:namespace ^quickshell-.*$"
    ];
  };
}
