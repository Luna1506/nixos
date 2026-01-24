{ username, ... }:

{
  environment.shellAliases = {
    # Passe den Pfad zu deinem Repo an, falls anders:
    rebuild = "sudo nixos-rebuild switch --flake ./dotfiles#nixos";
    update = "cd ./dotfiles && nix flake update && cd -";
    garbage = "sudo nix-collect-garbage";
    clear_efi = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5";
    clean = ''
      sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 &&
      sudo nix-collect-garbage
    '';
    setup_tim = "./update-setup.sh --username timp --fullname 'Tim Pagels' --nvidia-alt true --dest ~/src/nixos/dotfiles --monitor 'HDMI-A-1' --zoom '1.5'";
  };
}

