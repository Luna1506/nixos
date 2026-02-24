{ pkgs, lib, config, ... }:

let
  enableLiquidGlass = true;

  hypr = pkgs.hyprland;

  liquidGlassPlugin =
    pkgs.hyprlandPlugins.mkHyprlandPlugin (_finalAttrs: {
      pluginName = "liquid-glass";
      version = "git";

      src = pkgs.fetchFromGitHub {
        owner = "purple-lines";
        repo = "liquid-glass-plugin-hyprpm";
        rev = "main";
        sha256 = "sha256-awTwcDRSwV1HtBLA8+V+4exIFcqb2hmDzntlshd6Uf8=";
      };

      nativeBuildInputs = with pkgs; [
        pkg-config
        gnumake
      ];

      buildInputs = with pkgs; [
        pixman
        libdrm
        pango
        cairo
        libinput
        udev
        wayland

        # nixpkgs name (pkg-config name is xkbcommon)
        libxkbcommon

        # Hyprland for pkg-config + source
        hypr
      ];

      buildPhase = ''
        runHook preBuild

        # The plugin uses: <hyprland/src/...>
        # Create a builddir-local "hyprland" that points to Hyprland source.
        if [ -e "${hypr.src or ""}" ] && [ -n "${hypr.src or ""}" ]; then
          ln -sf "${hypr.src}" hyprland
        else
          echo "ERROR: pkgs.hyprland has no .src attribute in this nixpkgs."
          echo "Try pkgs.hyprland-unwrapped.src or pin a Hyprland source fetch."
          exit 1
        fi

        # IMPORTANT: because headers are included with angle brackets, the current dir
        # is not searched unless we add an include path. This makes <hyprland/src/...> work.
        export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I$PWD"

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
