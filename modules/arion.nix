{ lib, inputs, config, pkgs, ... }:

let cfg = config.modules.arion;
in {
  options.modules.arion = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.arion ];

    imports = [ inputs.arion.nixosModules.arion ../containers ];

    virtualisation.docker = {
      enable = true;
      liveRestore = false;
    };
    virtualisation.arion = { backend = "docker"; };
  };
}
