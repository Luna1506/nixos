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

                # ---- Hyprland headers / internals available as <hyprland/src/...> ----
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
                # Hyprland's Renderer.hpp includes ../../protocols/*.hpp which may not be present in plain src.
                # Try to find any installed protocols in the Hyprland output and copy them into hyprland/protocols.
                if [ ! -d hyprland/protocols ]; then
                  mkdir -p hyprland/protocols
                fi
                chmod -R u+w hyprland/protocols || true

                echo "Searching Hyprland package output for protocol headers (*.hpp)..."
                proto_dir="$(find "${hypr}" -maxdepth 6 -type d -name protocols 2>/dev/null | head -n 1 || true)"
                if [ -n "$proto_dir" ] && [ -d "$proto_dir" ]; then
                  echo "Found protocols dir: $proto_dir"
                  # Copy all .hpp from that protocols dir (some packages have nested structure)
                  find "$proto_dir" -type f -name '*.hpp' -print0 2>/dev/null | xargs -0 -I{} cp -f "{}" hyprland/protocols/ || true
                else
                  echo "No protocols dir found in Hyprland output; continuing (may still fail if required header missing)."
                fi

                # ---- Make sure -I$PWD is actually used by the compiler ----
                # Your build log shows the g++ command doesn't include any -I from Nix env,
                # so we patch the Makefile to include $(CXXFLAGS) in the compile line.
                if [ -f Makefile ]; then
                  echo "Patching Makefile to honor CXXFLAGS..."
                  # Insert $(CXXFLAGS) after 'g++' if not already present
                  # (safe-ish for this repo because the compile line is a single g++ invocation).
                  sed -i 's/^g++ /g++ $(CXXFLAGS) /' Makefile
                fi

                # Now set CXXFLAGS so <hyprland/src/...> resolves (angle brackets require explicit include paths)
                export CXXFLAGS="$CXXFLAGS -I$PWD"

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
