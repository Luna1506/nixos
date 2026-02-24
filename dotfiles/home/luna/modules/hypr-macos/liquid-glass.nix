{ pkgs, lib, config, ... }:

{
  options.hyprMacos.enableLiquidGlass = lib.mkOption {
    type = lib.types.bool;
    default = false; # ✅ erstmal AUS
  };

  config = {
    # Wenn aus, laden wir kein Plugin
    hyprMacos.liquidGlassPlugin = null;
  };
}
