{ username, ... }:

{
  environment.shellAliases = {
    # Passe den Pfad zu deinem Repo an, falls anders:
    rebuild = "sudo nixos-rebuild switch --flake /home/${username}/nixos/dotfiles#nixos";
    update = "cd /home/${username}/nixos/dotfiles && nix flake update && cd -";
  };
}

