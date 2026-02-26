{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flutter-dev = {
      url = "path:./flakes/flutter-dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "path:./home/luna/modules/quickshell/caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";

      # sorgt dafür, dass Caelestia/Quickshell nicht mit anderem nixpkgs/Qt baut
      inputs.quickshell.inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-cli.inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      username = "luna";
      fullname = "Luna Haiplick";
      nvidiaAlternative = true;
      monitor = "eDP-1";
      zoom = "1";
      git-name = "Luna";
      git-email = "mhaiplick1506@gmail.com";
      luna-path = true;
    in
    {
      # --- NixOS wie bisher ---
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs username fullname nvidiaAlternative monitor zoom git-name git-email luna-path;
        };

        modules = [
          ./hosts/laptop/default.nix

          home-manager.nixosModules.home-manager

          {
            home-manager.useUserPackages = true;

            home-manager.users.${username} =
              import ./home/${username}/home.nix;

            home-manager.extraSpecialArgs = {
              inherit inputs username fullname monitor zoom git-name git-email;
            };

            home-manager.backupFileExtension = "backup";
          }
        ];
      };

      packages.${system} = {
        caelestia-shell = inputs.caelestia-shell.packages.${system}.caelestia-shell;
        caelestia-shell-debug = inputs.caelestia-shell.packages.${system}.debug;
        caelestia-shell-with-cli = inputs.caelestia-shell.packages.${system}.with-cli;

        default = self.packages.${system}.caelestia-shell;
      };

      homeManagerModules = inputs.caelestia-shell.homeManagerModules or { };
    };
}
