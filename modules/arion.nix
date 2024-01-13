{ inputs, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.arion ];

  imports = [ inputs.arion.nixosModules.arion ];

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  users.extraUsers.user.extraGroups = [ "docker" ];

  virtualisation.arion = {
    backend = "docker";
  };
}