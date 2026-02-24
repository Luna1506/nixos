{ lib, ... }:

let
  # Tweak these to taste
  corner = 18;
  gap = 10;
  border = 2;

  blurSize = 10;
  blurPasses = 3;

  animSpeed = 1.0;
in
{
  # Export some shared values for other modules (optional)
  options.hyprMacos = {
    corner = lib.mkOption { type = lib.types.int; default = corner; };
    gap = lib.mkOption { type = lib.types.int; default = gap; };
    border = lib.mkOption { type = lib.types.int; default = border; };
    blurSize = lib.mkOption { type = lib.types.int; default = blurSize; };
    blurPasses = lib.mkOption { type = lib.types.int; default = blurPasses; };
    animSpeed = lib.mkOption { type = lib.types.float; default = animSpeed; };
  };

  config.hyprMacos = {
    inherit corner gap border blurSize blurPasses animSpeed;
  };
}
