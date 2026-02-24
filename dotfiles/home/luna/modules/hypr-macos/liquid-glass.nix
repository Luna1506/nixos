{ pkgs, lib, config, ... }:

let
  # Set to true to enable plugin build + loading
  enableLiquidGlass = true;

  liquidGlassPlugin =
    pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
      pluginName = "liquid-glass";
      version = "git";

      src = pkgs.fetchFromGitHub {
        owner = "purple-lines";
        repo = "liquid-glass-plugin-hyprpm";

        # Bitte pinnen, wenn du willst. Für jetzt geht main.
        rev = "main";

        # Wichtig: fakeSha256, damit Nix dir beim Build den echten SRI sha256 ausspuckt
        sha256 = lib.fakeSha256;
      };

      nativeBuildInputs = with pkgs; [
        pkg-config
        gnumake
      ];

      buildPhase = ''
        runHook preBuild
        make all
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        install -m755 liquid-glass.so $out/lib/liquid-glass.so
        runHook postInstall
      '';

      meta = with lib; {
        description = "Apple-style Liquid Glass effect plugin for Hyprland";
        homepage = "https://github.com/purple-lines/liquid-glass-plugin-hyprpm";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    });
in
{
  options.hyprMacos.enableLiquidGlass = lib.mkOption {
    type = lib.types.bool;
    default = enableLiquidGlass;
  };

  config = lib.mkMerge [
    (lib.mkIf config.hyprMacos.enableLiquidGlass {
      hyprMacos.liquidGlassPlugin = liquidGlassPlugin;
    })

    (lib.mkIf (!config.hyprMacos.enableLiquidGlass) {
      hyprMacos.liquidGlassPlugin = null;
    })
  ];
}
