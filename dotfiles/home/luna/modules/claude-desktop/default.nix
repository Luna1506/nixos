{ lib, pkgs, ... }:
{
  # Home Manager evaluates its own nixpkgs (no useGlobalPkgs), so the system's
  # allowUnfree doesn't apply here. Allow exactly this one unfree package.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-desktop" ];

  # Official Claude Desktop Linux build.
  home.packages = [ (pkgs.callPackage ./package.nix { }) ];
}
