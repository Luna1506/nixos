{
  description = "Hyprland Liquid Glass Plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, hyprland }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      hyprlandPkg = hyprland.packages.${system}.hyprland;
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "hypr-liquid-glass";
        version = "0.1.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
        ];

        buildInputs = with pkgs; [
          hyprlandPkg
          hyprland.packages.${system}.hyprland-dev
          wayland
          wayland-protocols
          libGL
          libGLU
          mesa
          xorg.libX11
          cairo
          pango
          pixman
        ];

        cmakeFlags = [
          "-DHYPRLAND_HEADERS=${hyprland.packages.${system}.hyprland-dev}/include"
          "-DCMAKE_BUILD_TYPE=Release"
        ];

        installPhase = ''
          mkdir -p $out/lib
          cp libhypr-liquid-glass.so $out/lib/
        '';

        meta = {
          description = "Liquid Glass effect plugin for Hyprland";
          platforms = [ "x86_64-linux" "aarch64-linux" ];
        };
      };
    };
}