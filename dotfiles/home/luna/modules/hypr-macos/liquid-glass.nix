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

                # ---- Protocol headers (cursor-shape-v1.hpp etc.) ----
                # If Hyprland source contains a protocols/ dir, ensure it's at hyprland/protocols.
                if [ ! -d hyprland/protocols ]; then
                  # sometimes protocols are nested; try to locate within the copied source
                  pdir="$(find hyprland -maxdepth 3 -type d -name protocols 2>/dev/null | head -n 1 || true)"
                  if [ -n "$pdir" ] && [ -d "$pdir" ]; then
                    echo "Found protocols dir inside Hyprland source: $pdir"
                    # If it's not already hyprland/protocols, copy it there
                    rm -rf hyprland/protocols
                    mkdir -p hyprland/protocols
                    cp -r "$pdir/." hyprland/protocols/
                    chmod -R u+w hyprland/protocols || true
                  else
                    echo "No protocols dir found in Hyprland source tree (may fail later on cursor-shape-v1.hpp)."
                  fi
                fi

                # ---- IMPORTANT: Makefile hardcodes 'g++' and ignores CXXFLAGS.
                # Put a g++ wrapper first in PATH to inject include paths.
                cat > ./g++ <<EOF
        #!/usr/bin/env bash
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
