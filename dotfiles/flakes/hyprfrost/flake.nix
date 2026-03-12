{
  description = "hyprfrost – macOS-style frosted-glass Hyprland plugin";

  # ── inputs ──────────────────────────────────────────────────────────────────
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pin to the same Hyprland the user is likely running.
    # Override via  `nix flake update hyprland`  or adjust the URL below.
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ── outputs ─────────────────────────────────────────────────────────────────
  outputs = { self, nixpkgs, hyprland }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAll = f: nixpkgs.lib.genAttrs supportedSystems f;

      # Build the .so for a given system
      mkPlugin = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hyprUnwrapped = hyprland.packages.${system}.hyprland-unwrapped;
        in
        pkgs.stdenv.mkDerivation {
          pname = "hyprfrost";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ];

          # hyprUnwrapped.dev provides hyprland.pc + all Hyprland source headers.
          # Its buildInputs satisfy all of hyprland.pc's Requires: transitively.
          buildInputs = [ hyprUnwrapped.dev ] ++ hyprUnwrapped.buildInputs ++ (with pkgs; [
            mesa
            libGL
          ]);

          # cmake will pick up hyprland.pc via PKG_CONFIG_PATH (set by Nix)
          cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

          # Let cmake handle install paths (uses the install() directive in
          # CMakeLists.txt → $out/lib/hyprfrost/hyprfrost.so)
          installPhase = ''
            runHook preInstall
            cmake --install . --prefix "$out"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "macOS-style frosted-glass effect for Hyprland windows";
            homepage = "https://github.com/your-user/hyprfrost";
            license = licenses.mit;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" ];
          };
        };

    in
    {
      # ── per-system packages ────────────────────────────────────────────────
      packages = forAll (system: {
        default = mkPlugin system;
        hyprfrost = mkPlugin system;
      });

      # ── devShell (for local hacking) ───────────────────────────────────────
      devShells = forAll (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hyprUnwrapped = hyprland.packages.${system}.hyprland-unwrapped;
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ cmake pkg-config clang-tools ];
            buildInputs = [ hyprUnwrapped.dev ] ++ hyprUnwrapped.buildInputs ++ (with pkgs; [
              mesa
              libGL
            ]);
            shellHook = ''
              echo "hyprfrost dev shell ready"
              echo "Build: cmake -B build && cmake --build build"
            '';
          };
        });

      # ── NixOS module ──────────────────────────────────────────────────────
      nixosModules.default = { config, pkgs, lib, ... }:
        let
          cfg = config.programs.hyprfrost;
          system = pkgs.system;
          pkg = self.packages.${system}.hyprfrost;
        in
        {
          options.programs.hyprfrost = {
            enable = lib.mkEnableOption
              "hyprfrost – frosted-glass effect for Hyprland";

            # ── Frosted-glass look ─────────────────────────────────────────
            tintColor = lib.mkOption {
              type = lib.types.str;
              default = "0.12 0.12 0.18";
              description = ''
                Space-separated R G B float values (0.0–1.0) for the glass tint.
                Example: "0.94 0.94 0.94" for a near-white macOS-style glass.
              '';
            };

            tintAlpha = lib.mkOption {
              type = lib.types.float;
              default = 0.55;
              description = ''
                Opacity of the glass tint layer (0.0 = fully transparent,
                1.0 = fully opaque).  0.5–0.6 gives a natural glass look.
              '';
            };

            noiseAmount = lib.mkOption {
              type = lib.types.float;
              default = 0.04;
              description = ''
                Strength of the procedural frost grain (0 = disabled).
                Values above ~0.10 become visually heavy.
              '';
            };

            noiseScale = lib.mkOption {
              type = lib.types.float;
              default = 280.0;
              description = ''
                Pixel size of the noise grid.  Smaller = finer grain (e.g. 180),
                larger = coarser (e.g. 400).
              '';
            };

            rounding = lib.mkOption {
              type = lib.types.int;
              default = -1;
              description = ''
                Corner radius in pixels.  -1 inherits Hyprland's
                decoration:rounding value.
              '';
            };

            # ── Blur passthrough ───────────────────────────────────────────
            # hyprfrost relies on Hyprland's built-in blur.  The module can
            # automatically enable / configure it.
            blur = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Automatically enable Hyprland decoration:blur when hyprfrost
                  is active.  Disable if you manage blur settings yourself.
                '';
              };

              size = lib.mkOption {
                type = lib.types.int;
                default = 8;
                description = "Blur kernel size (larger = blurrier).";
              };

              passes = lib.mkOption {
                type = lib.types.int;
                default = 3;
                description = "Number of blur passes (more = smoother).";
              };

              noise = lib.mkOption {
                type = lib.types.float;
                default = 0.0117;
                description = "Hyprland's built-in blur noise amount.";
              };

              contrast = lib.mkOption {
                type = lib.types.float;
                default = 0.8916;
                description = "Hyprland's built-in blur contrast.";
              };

              brightness = lib.mkOption {
                type = lib.types.float;
                default = 0.8172;
                description = "Hyprland's built-in blur brightness.";
              };

              vibrancy = lib.mkOption {
                type = lib.types.float;
                default = 0.1696;
                description = "Hyprland's built-in blur vibrancy.";
              };
            };

            # ── Derived output (read-only) ─────────────────────────────────
            # Auto-generated Hyprland config snippet.  Add to your config:
            #   wayland.windowManager.hyprland.extraConfig =
            #     config.programs.hyprfrost.hyprlandConfig;
            hyprlandConfig = lib.mkOption {
              type = lib.types.str;
              description = "Generated Hyprland configuration snippet for hyprfrost.";
            };
          };

          # ── Implementation ─────────────────────────────────────────────────
          config = lib.mkIf cfg.enable {
            # Make the .so accessible system-wide
            environment.systemPackages = [ pkg ];

            # Inject the plugin into Hyprland's config via home-manager or
            # the Hyprland NixOS module's extraConfig option.
            # We produce a snippet that both approaches can consume.
            #
            # If you use the official hyprland NixOS module, add:
            #   wayland.windowManager.hyprland.extraConfig = config.programs.hyprfrost.hyprlandConfig;
            programs.hyprfrost.hyprlandConfig =
              let
                # lib.splitString splits on a literal character – correct for
                # space-separated "R G B" strings (builtins.splitVersion splits
                # on "." and would produce wrong results here).
                rgb = lib.splitString " " cfg.tintColor;
                r = builtins.elemAt rgb 0;
                g = builtins.elemAt rgb 1;
                b = builtins.elemAt rgb 2;
              in
              ''
                # ── hyprfrost plugin ──────────────────────────────────────────
                plugin = ${pkg}/lib/hyprfrost/hyprfrost.so

                plugin {
                  hyprfrost {
                    enabled      = 1
                    tint_r       = ${r}
                    tint_g       = ${g}
                    tint_b       = ${b}
                    tint_alpha   = ${toString cfg.tintAlpha}
                    noise_amount = ${toString cfg.noiseAmount}
                    noise_scale  = ${toString cfg.noiseScale}
                    rounding     = ${toString cfg.rounding}
                  }
                }
              ''
              + lib.optionalString cfg.blur.enable ''

                decoration {
                  blur {
                    enabled    = true
                    size       = ${toString cfg.blur.size}
                    passes     = ${toString cfg.blur.passes}
                    noise      = ${toString cfg.blur.noise}
                    contrast   = ${toString cfg.blur.contrast}
                    brightness = ${toString cfg.blur.brightness}
                    vibrancy   = ${toString cfg.blur.vibrancy}
                  }
                }
              '';
          };
        };

      # ── home-manager module ────────────────────────────────────────────────
      # Convenience wrapper for home-manager users.
      homeManagerModules.default = { config, pkgs, lib, ... }:
        let
          cfg = config.wayland.windowManager.hyprland.hyprfrost;
          system = pkgs.system;
          pkg = self.packages.${system}.hyprfrost;
        in
        {
          options.wayland.windowManager.hyprland.hyprfrost = {
            enable = lib.mkEnableOption "hyprfrost frosted-glass plugin";
            tintColor = lib.mkOption { type = lib.types.str; default = "0.12 0.12 0.18"; };
            tintAlpha = lib.mkOption { type = lib.types.float; default = 0.55; };
            noiseAmount = lib.mkOption { type = lib.types.float; default = 0.04; };
            noiseScale = lib.mkOption { type = lib.types.float; default = 280.0; };
            rounding = lib.mkOption { type = lib.types.int; default = -1; };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ pkg ];

            wayland.windowManager.hyprland.extraConfig =
              let
                parts = lib.splitString " " cfg.tintColor;
                r = builtins.elemAt parts 0;
                g = builtins.elemAt parts 1;
                b = builtins.elemAt parts 2;
              in
              ''
                plugin = ${pkg}/lib/hyprfrost/hyprfrost.so
                plugin {
                  hyprfrost {
                    enabled      = 1
                    tint_r       = ${r}
                    tint_g       = ${g}
                    tint_b       = ${b}
                    tint_alpha   = ${toString cfg.tintAlpha}
                    noise_amount = ${toString cfg.noiseAmount}
                    noise_scale  = ${toString cfg.noiseScale}
                    rounding     = ${toString cfg.rounding}
                  }
                }
                decoration {
                  blur {
                    enabled    = true
                    size       = 8
                    passes     = 3
                    noise      = 0.0117
                    contrast   = 0.8916
                    brightness = 0.8172
                    vibrancy   = 0.1696
                  }
                }
              '';
          };
        };
    };
}
