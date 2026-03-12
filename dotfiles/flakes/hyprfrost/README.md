# Hyprfrost

## Funktion
```
  Wallpaper / andere Fenster
        ↓
  Hyprland Kawase-Blur  (decoration:blur:enabled = true)
        ↓
  CFrostedGlassDecoration  (DECORATION_LAYER_UNDER)
    1. tintiertes semi-transparentes Rect   → Glasfarbe
    2. prozedurales Noise-Quad (GLSL fbm)  → Frost-Korn
        ↓
  Fenster-Surface
```

## Verwendung

### flake.nix deines Systems
```
inputs.hyprfrost.url = "github:dein-user/hyprfrost";
```
### NixOS-Modul
```
imports = [ hyprfrost.nixosModules.default ];
programs.hyprfrost = {
  enable     = true;
  tintColor  = "0.12 0.12 0.18";   # R G B (0–1)
  tintAlpha  = 0.55;
  noiseAmount = 0.04;
};
wayland.windowManager.hyprland.extraConfig =
  config.programs.hyprfrost.hyprlandConfig;
```
### Oder Home Manager
```
imports = [ hyprfrost.homeManagerModules.default ];
wayland.windowManager.hyprland.hyprfrost.enable = true;
```
