{ inputs, ... }:
{
  imports = [ inputs.kartei.homeManagerModules.default ];
  services.kartei.enable = true;
}
