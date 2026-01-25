{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim # editor
    ghostty # terminal
    wofi # application manager
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # browser
    firefox # browser
    yazi # terminal based file manager
    nautilus # file manager
    steam
    vulkan-loader
    vulkan-validation-layers
    gnome-disk-utility # disks app from gnome
    bibata-cursors # cursor
    vesktop # discord for linux
    spotify
    waybar
    hyprpaper # wallpaper manager
    hyprlock
    grim # for screenshots
    slurp # for screenshots to select the area
    wl-clipboard # puts screenshots in clipboard
    polkit # for authentification
    sl
    git
    jetbrains.idea
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
  ];
}

