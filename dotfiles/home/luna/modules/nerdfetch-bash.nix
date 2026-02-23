{ config, lib, pkgs, ... }:

{
  programs.bash.enable = true;

  programs.bash.initExtra = lib.mkAfter ''
    # Nerdfetch nur in interaktiven Shells
    if [[ $- == *i* ]] && command -v nerdfetch >/dev/null; then
      nerdfetch
    fi
  '';
}
