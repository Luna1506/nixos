# Quickpanel

## flake.nix deines Systems
```
inputs.quickpanel.url = "github:dein-user/quickpanel";
```
## home.nix
```
imports = [ inputs.quickpanel.homeManagerModules.default ];

programs.quickpanel = {
  enable   = true;
  keybind  = "SUPER, P";      # Hyprland Shortcut
  autostart = true;           # systemd user service
  extraPackages = with pkgs; [ networkmanager bluez upower playerctl ];
};
```
