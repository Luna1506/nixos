{ ... }:

{
  xdg.configFile."ghostty/config".text = ''
    # Ghostty: make the terminal itself translucent so "glass" is visible.
    background-opacity = 0.78
    window-padding-x = 10
    window-padding-y = 10

    # Optional: slightly larger font tends to look more "mac"
    font-size = 13
  '';
}
