{ ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Luna";
      email = "mhaiplick1506@gmail.com";
    };
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}

