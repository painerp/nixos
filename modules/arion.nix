{ inputs, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.arion ];

  imports = [ inputs.arion.nixosModules.arion ];

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  virtualisation.arion = { backend = "docker"; };
}
