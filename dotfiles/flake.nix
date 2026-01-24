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
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      nixos =
        let
          system = "x86_64-linux";
          username = "luna";
          nvidiaAlternative = true;
          monitor = "eDP-1";
          zoom = "1";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs =
            {
              inherit inputs username nvidiaAlternative monitor zoom;
            };
          modules = [
            ./hosts/laptop/default.nix

            # Home Manager als NixOS-Modul
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/${username}/home.nix;
              home-manager.extraSpecialArgs = { inherit inputs username monitor zoom; };
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
    };
  };
}

