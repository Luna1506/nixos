{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    ghostty # terminal
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # browser
    firefox # browser
    nautilus # file manager
    steam
    vulkan-loader
    vulkan-validation-layers
    gnome-disk-utility # disks app from gnome
    bibata-cursors # cursor
    vesktop # discord for linux
    cider-2
    grim # for screenshots
    slurp # for screenshots to select the area
    wl-clipboard # puts screenshots in clipboard
    polkit # for authentification
    sl
    jetbrains-toolbox
    catppuccin-sddm # sddm theme
    lazydocker # terminal based gui for docker
    pavucontrol # application for sound controls
    wireplumber # for sound controls
    networkmanagerapplet
    networkmanager
    ncurses
    blueman # for bluetooth
    bluez # for bluetooth
    wlogout
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    mission-center # task manager
    nvtopPackages.nvidia # task manager for nvidia
    traceroute
    tree
    nwg-dock-hyprland
    jq
    procps
    unzip
    temurin-bin-25
    bruno
    teamspeak6
    pipewire
    pulseaudio

    # BEGIN AUTO PACKAGES
    element-desktop
    # END AUTO PACKAGES
  ];

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    glib
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    libGL
  ];

  programs.java = {
    enable = true;
    package = pkgs.temurin-bin-25;
  };
}

