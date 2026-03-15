{
  description = "quickpanel – Quickshell status panel + macOS dock for Hyprland";

  inputs = {
    nixpkgs.url  = "github:NixOS/nixpkgs/nixos-unstable";

    # Official Quickshell flake
    quickshell = {
      url    = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll  = f: nixpkgs.lib.genAttrs systems f;

      qmlSrc  = ./qml;   # the qml/ directory next to this flake
    in {

      # ── Package: just the QML sources + a wrapper script ──────────────────
      packages = forAll (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          qs   = quickshell.packages.${system}.default;
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname   = "quickpanel";
            version = "0.1.0";
            src     = qmlSrc;

            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/quickpanel
              cp -r . $out/share/quickpanel/

              # Convenience wrapper: qs --config <path>
              mkdir -p $out/bin
              # Note: heredoc must be unindented so the shebang has no leading spaces
              cat > $out/bin/quickpanel << 'WRAPPER'
#!/bin/sh
WRAPPER
              # Patch in the store path (can't use $-variables inside single-quoted heredoc)
              printf '#!/bin/sh\nexec %s/bin/qs --config %s/share/quickpanel "$@"\n' \
                "${qs}" "$out" > $out/bin/quickpanel
              chmod +x $out/bin/quickpanel
              runHook postInstall
            '';

            meta = {
              description = "Quickshell status + media panel for Hyprland/NixOS";
            };
          };
        });

      # ── Home-Manager module ────────────────────────────────────────────────
      homeManagerModules.default = { config, pkgs, lib, ... }:
        let
          cfg    = config.programs.quickpanel;
          system = pkgs.system;
          qs     = quickshell.packages.${system}.default;
          pkg    = self.packages.${system}.default;
        in {
          options.programs.quickpanel = {
            enable = lib.mkEnableOption
              "quickpanel – Quickshell status panel + macOS-style dock for Hyprland";

            # ── Status panel ────────────────────────────────────────────────
            keybind = lib.mkOption {
              type    = lib.types.str;
              default = "SUPER, P";
              description = ''
                Hyprland keybind that toggles the status/media panel.
                Format: "MODS, KEY"  e.g. "SUPER, P" or "SUPER SHIFT, space".
              '';
            };

            # ── Dock ────────────────────────────────────────────────────────
            dock = {
              enable = lib.mkOption {
                type    = lib.types.bool;
                default = true;
                description = ''
                  Enable the macOS-style dock.
                  The dock appears automatically whenever the active Hyprland
                  workspace has no mapped windows.  No keybind is needed.
                '';
              };
            };

            # ── General ─────────────────────────────────────────────────────
            autostart = lib.mkOption {
              type    = lib.types.bool;
              default = true;
              description = "Start Quickshell automatically with the Hyprland session.";
            };

            extraPackages = lib.mkOption {
              type    = lib.types.listOf lib.types.package;
              default = [];
              description = ''
                Additional runtime packages made available to the QML scripts.
                Recommended: [ pkgs.networkmanager pkgs.bluez pkgs.upower pkgs.playerctl ]
              '';
            };
          };

          config = lib.mkIf cfg.enable {
            # ── Install packages ───────────────────────────────────────────────
            home.packages = [ qs pkg ] ++ cfg.extraPackages;

            # ── QML config files → ~/.config/quickshell/ ──────────────────────
            # Quickshell looks for shell.qml in ~/.config/quickshell/ by default.
            # Dock files (Dock.qml / DockItem.qml) are excluded when dock.enable=false
            # by not writing them – shell.qml still references them, so disable dock
            # by setting dock.enable=false AND removing the `Dock {}` line manually,
            # OR (simpler) just leave dock.enable=true.
            xdg.configFile =
              let
                allFiles  = builtins.readDir qmlSrc;
                dockFiles = [ "Dock.qml" "DockItem.qml" "PinnedItem.qml" "AppMenuButton.qml" ];
                filtered  = if cfg.dock.enable
                            then lib.filterAttrs (_: t: t == "regular") allFiles
                            else lib.filterAttrs (n: t: t == "regular" && !(builtins.elem n dockFiles)) allFiles;
                fileMappings = lib.mapAttrs' (name: _:
                  lib.nameValuePair
                    ("quickshell/" + name)
                    { source = "${qmlSrc}/${name}"; }
                ) filtered;
                iconMapping = lib.optionalAttrs cfg.dock.enable {
                  "quickshell/icons" = { source = "${qmlSrc}/icons"; recursive = true; };
                };
              in fileMappings // iconMapping;

            # ── systemd user service (autostart) ──────────────────────────────
            systemd.user.services.quickshell = lib.mkIf cfg.autostart {
              Unit = {
                Description   = "Quickshell compositor shell";
                After         = [ "graphical-session.target" ];
                PartOf        = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${qs}/bin/qs";
                Restart   = "on-failure";
                # Give Hyprland a second to start before launching
                ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };

            # ── Hyprland keybind ───────────────────────────────────────────────
            wayland.windowManager.hyprland.extraConfig = ''
              # quickpanel status/media toggle
              bind = ${cfg.keybind}, exec, ${qs}/bin/qs ipc call quickpanel toggle

              # The dock is automatic (appears on empty workspaces) – no bind needed.
              # Recommended: enable Hyprland blur so frosted glass looks correct.
              #   decoration { blur { enabled = true; size = 8; passes = 3 } }
            '';
          };
        };
    };
}
