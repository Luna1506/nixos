{ pkgs, lib, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    ghostty # terminal
    iloader # installiert SideStore aufs iPhone (NAKLearn)
    libimobiledevice # iPhone-Tools (idevice_id, ideviceinfo)
    # browser; ffmpeg dazu, sonst kein H.264 (Zen bringt nur ffvpx mit, Firefox aus nixpkgs hat ffmpeg)
    (symlinkJoin {
      name = "zen-browser";
      paths = [ inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/zen --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ ffmpeg.lib ]}";
    })
    firefox # browser
    nautilus # file manager
    loupe # image viewer
    steam
    # minecraft launcher (fabric, mods)
    # ohne gtk3-platformtheme: Prism lädt alle Qt-Styles, qt6gtk2 (GTK2) + gtk3 im selben Prozess = Segfault
    (symlinkJoin {
      name = "prismlauncher";
      paths = [ prismlauncher ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/prismlauncher --unset QT_QPA_PLATFORMTHEME";
    })
    vulkan-loader
    vulkan-validation-layers
    gnome-disk-utility # disks app from gnome
    bibata-cursors # cursor
    vesktop # discord for linux
    spotify
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
    traceroute
    tree
    nwg-dock-hyprland
    jq
    procps
    unzip
    temurin-bin-25
    bruno
    teamspeak6-client
    pipewire
    pulseaudio
    figma-linux

    # BEGIN AUTO PACKAGES
    teams-for-linux
    element-desktop
    fastfetch
    cmatrix
    cava
    mapscii
    nerdfetch
    hypridle
    hyprpicker
    playerctl
    cliphist
    protonup-qt
    cbonsai
    lavat
    nyancat
    asciiquarium
    nodejs
    claude-code
    vscodium
    python3
    nuclei
    # END AUTO PACKAGES
  ];

  # Bilder standardmäßig mit Loupe öffnen
  xdg.mime.defaultApplications = {
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
  };

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    glib
    libx11
    libxcursor
    libxrandr
    libxi
    libGL
  ];

  programs.java = {
    enable = true;
    package = pkgs.temurin-bin-25;
  };

  # iPhone per USB (SideStore für NAKLearn): usbmuxd
  services.usbmuxd.enable = true;
}

