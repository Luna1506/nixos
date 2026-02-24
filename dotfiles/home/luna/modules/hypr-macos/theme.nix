{ lib, ... }:

let
  corner = 18;
  gap = 10;
  border = 2;

  blurSize = 10;
  blurPasses = 3;

  animSpeed = 1.0;
in
{
  options.hyprMacos = {
    corner = lib.mkOption {
      type = lib.types.int;
      default = corner;
    };

    gap = lib.mkOption {
      type = lib.types.int;
      default = gap;
    };

    border = lib.mkOption {
      type = lib.types.int;
      default = border;
    };

    blurSize = lib.mkOption {
      type = lib.types.int;
      default = blurSize;
    };

    blurPasses = lib.mkOption {
      type = lib.types.int;
      default = blurPasses;
    };

    animSpeed = lib.mkOption {
      type = lib.types.float;
      default = animSpeed;
    };

    # 🔥 DIESE FEHLTEN:

    binds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    windowRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    liquidGlassPlugin = lib.mkOption {
      type = lib.types.package;
      default = null;
    };
  };

  config.hyprMacos = {
    inherit
      corner
      gap
      border
      blurSize
      blurPasses
      animSpeed;
  };
}
