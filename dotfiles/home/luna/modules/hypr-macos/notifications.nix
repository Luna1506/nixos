{ ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 420;
      control-center-height = 720;

      # A bit "glass-like"
      cssPriority = "application";
    };

    style = ''
      * {
        border-radius: 18px;
      }

      .control-center {
        background: rgba(20,20,24,0.55);
      }

      .notification {
        background: rgba(255,255,255,0.10);
      }
    '';
  };
}
