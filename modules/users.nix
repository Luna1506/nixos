{ username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = "Luna Haiplick";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = [ ];
  };
}

