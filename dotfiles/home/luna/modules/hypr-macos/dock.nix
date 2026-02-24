{ ... }:

{
  xdg.configFile."nwg-dock-hyprland/style.css".text = ''
    * {
      border-radius: 18px;
      font-family: sans-serif;
    }

    window {
      background: rgba(255,255,255,0.06);
      padding: 10px;
    }

    button {
      background: rgba(255,255,255,0.08);
      margin: 6px;
      padding: 8px;
      border-radius: 16px;
    }

    button:hover {
      background: rgba(255,255,255,0.14);
    }
  '';

  # Minimal config; passt ggf. an, je nachdem wie du den Dock triggern willst
  xdg.configFile."nwg-dock-hyprland/config.json".text = ''
    {
      "position": "bottom",
      "layer": "top",
      "icon_size": 44,
      "margin_bottom": 18,
      "border_radius": 18,
      "show_names": false
    }
  '';
}
