{ username, luna-path, ... }:

let
  homeDir = "/home/${username}";
  dotfilesAbs = "${homeDir}/nixos/dotfiles";
  dotfilesPath =
    if luna-path
    then dotfilesAbs
    else "./dotfiles"; # fallback absolut (oder "${homeDir}/dotfiles" wenn du das nutzt)
in
{
  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ${dotfilesPath}#nixos";
    rb = "sudo nixos-rebuild switch --flake ${dotfilesPath}#nixos";
    update = "cd ${dotfilesPath} && nix flake update && cd -";

    garbage = "sudo nix-collect-garbage";
    clear_efi = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5";
    clean = ''
      sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 &&
      sudo nix-collect-garbage
    '';
  };
}

