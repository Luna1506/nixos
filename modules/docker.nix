{ ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.users.luna = {
    extraGroups = [ "docker" ];
  };
}

