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
        libxkbcommon
        hypr
      ];

      buildPhase = ''
                runHook preBuild

                # ---- make Hyprland internals available as <hyprland/src/...> ----
                if [ -e "${hypr.src or ""}" ] && [ -n "${hypr.src or ""}" ]; then
                  echo "Copying Hyprland source into builddir (writeable)..."
                  rm -rf hyprland
                  mkdir -p hyprland
                  cp -r "${hypr.src}/." hyprland/
                  chmod -R u+w hyprland || true
                else
                  echo "ERROR: pkgs.hyprland has no .src attribute in this nixpkgs."
                  echo "Try pkgs.hyprland-unwrapped.src or pin/fetch Hyprland source."
                  exit 1
                fi

                # Ensure version.h exists (often generated in Hyprland build)
                if [ ! -f hyprland/src/version.h ]; then
                  echo "hyprland/src/version.h missing — generating a minimal stub"
                  mkdir -p hyprland/src
                  chmod -R u+w hyprland/src || true
                  cat > hyprland/src/version.h <<'EOF'
        #pragma once
        #ifndef HYPRLAND_VERSION
        #define HYPRLAND_VERSION "unknown"
        #endif
        #ifndef HYPRLAND_VERSION_COMMIT
        #define HYPRLAND_VERSION_COMMIT "unknown"
        #endif
        #ifndef HYPRLAND_VERSION_DIRTY
        #define HYPRLAND_VERSION_DIRTY "0"
        #endif
        #ifndef HYPRLAND_VERSION_TAG
        #define HYPRLAND_VERSION_TAG "unknown"
        #endif
        EOF
                fi

                # ---- g++ wrapper because Makefile hardcodes g++ and ignores flags ----
                cat > ./g++ <<EOF
        #!${pkgs.bash}/bin/bash
        exec ${pkgs.gcc}/bin/g++ -I"$PWD" "\$@"
        EOF
                chmod +x ./g++
                export PATH="$PWD:$PATH"

                # Build
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
