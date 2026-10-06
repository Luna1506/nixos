{ inputs, ... }:
{
  imports = [ inputs.naklearn.homeManagerModules.default ];
  services.naklearn.enable = true;
}
