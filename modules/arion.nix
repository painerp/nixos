{ lib, inputs, config, pkgs, ... }:

let cfg = config.modules.arion;
in {
  options.modules.arion = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [ inputs.arion.nixosModules.arion ../containers ];

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.arion ];

    virtualisation.docker = {
      enable = true;
      liveRestore = false;
    };
    virtualisation.arion = { backend = "docker"; };
  };
}
