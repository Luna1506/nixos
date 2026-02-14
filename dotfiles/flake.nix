{
  description = "Modulares NixOS-Setup (Host: nixos) mit Home Manager-Option";

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

      teamspeak6Overlay = final: prev: {
        teamspeak6 = final.callPackage ./pkgs/teamspeak6 { };
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs username fullname nvidiaAlternative monitor zoom git-name git-email luna-path;
        };

        modules = [
          ({ ... }: {
            nixpkgs.overlays = [ teamspeak6Overlay ];
          })

          ./hosts/laptop/default.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home/${username}/home.nix;

            home-manager.extraSpecialArgs = {
              inherit inputs username fullname monitor zoom git-name git-email;
            };

            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
}
