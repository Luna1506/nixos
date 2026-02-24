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

        # Bitte später auf einen Commit pinnen, aber main geht erstmal.
        rev = "main";

        # ✅ Nix hat dir diesen Hash gegeben:
        sha256 = "sha256-awTwcDRSwV1HtBLA8+V+4exIFcqb2hmDzntlshd6Uf8=";
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
